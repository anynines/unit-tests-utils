require 'httparty'
require_relative 'postgresql_client'

class UnitTestsUtils::PGWebServiceClient
  attr_reader :manifest, :manifest_name, :password

  DEFAULT_WEB_SERVICE_PASSWORD = 'password'

  def initialize(manifest, options = {})
    @manifest_name = options[:new_manifest_name] || manifest.name
    @password = options[:pg_web_service_password] || DEFAULT_WEB_SERVICE_PASSWORD

    @manifest = manifest
  end

  def self.master_hostname(manifest)
    "#{manifest.name}-psql-master-alias.node.#{manifest.properties['consul']['dc']}.#{manifest.properties['consul']['domain']}"
  end

  def node_ips
    instances = UnitTestsUtils::Bosh.instance_status(manifest_name, manifest.instance_names.first)
    instances.map { |instance| instance["ips"] }
  end

  def wait_cluster_is_ready(period = 5, retries = 1200)
    counter = 0
    while ! is_cluster_ready do
      sleep(period)

      if counter >= retries
        raise Exception.new("Timed out waiting for deployment to be ready")
      end
      counter += 1
    end
  end

  def master_node
    node_ips.each do |node_ip|
      begin
        result = HTTParty.get("http://#{node_ip}:63145/v1/master", basic_auth: webservice_credentials)

        logger.debug("Response from *#{node_ip}* - Master node: #{result}")

        if result.response.kind_of?(Net::HTTPSuccess)
          body = JSON.parse(result.body)
          return body if body["data"] != "No Quorum"
        end
      rescue Exception
        logger.debug("Could not reach node: #{node_ip}")
      end
    end
    raise Exception.new("Could not reach any node")
  end

  def master_ip
    return master_node["data"]["node_ip"]
  end

  def standby_ips
    standby_nodes.map { |node| node["data"]["node_ip"] }
  end

  def standby_nodes
    nodes = node_ips.map do |node_ip|
      begin
        JSON.parse(HTTParty.get("http://#{node_ip}:63145/v1/status", basic_auth: webservice_credentials).body)
      rescue Exception
        logger.debug("Could not reach node: #{node_ip}")
        nil
      end
    end
    return nodes.select { |node| !node.nil? && node["status"] == "succeeded" && node["data"]["mode"] == "standby" }
  end

  def standby_min_age
    return 60 if manifest.properties["postgresql-info-webservice"].nil?
    return 60 if manifest.properties["postgresql-info-webservice"]["monitor"].nil?
    return 60 if manifest.properties["postgresql-info-webservice"]["monitor"]["min_standby_age"].nil?
    return manifest.properties["postgresql-info-webservice"]["monitor"]["min_standby_age"].to_i
  end

  def check_interval
    return 2 if manifest.properties["postgresql-info-webservice"].nil?
    return 2 if manifest.properties["postgresql-info-webservice"]["monitor"].nil?
    return 2 if manifest.properties["postgresql-info-webservice"]["monitor"]["heartbeat_interval"].nil?
    return manifest.properties["postgresql-info-webservice"]["monitor"]["heartbeat_interval"].to_i
  end

  def wait_monitor_block_node(node_id, sleeping_period = 5, retries = 1200)
    logger.debug("Waiting for node to be rejecting connections - node_id: *#{node_id}*")

    counter = 0
    is_blocked = false
    while ! is_blocked do
      node = cluster_status.select do |node|
        logger.debug("Checking node - node_id: *#{node_id}*, node: *#{node}*")
        node["data"]["id"] == node_id
      end.first
      logger.debug("Got node - node: *#{node}*")
      is_blocked = node["data"]["blocked"] if !node.nil?

      sleep(sleeping_period)

      if counter >= retries
        raise Exception.new("Timed out waiting for node to be rejecting connections")
      end
      counter += 1
    end
    logger.debug("Finished waiting node to be rejecting connections")
  end

  def wait_monitor_unblock_node(node_id, sleeping_period = 5, retries = 1200)
    logger.debug("Waiting for node to accept connections - node_id: *#{node_id}*")

    counter = 0
    is_blocked = true
    while is_blocked do
      node = cluster_status.select do |node|
        logger.debug("Checking node - node_id: *#{node_id}*, node: *#{node}*")
        node["data"]["id"] == node_id
      end.first
      logger.debug("Got node - node: *#{node}*")
      is_blocked = node["data"]["blocked"] if !node.nil?

      sleep(sleeping_period)

      if counter >= retries
        raise Exception.new("Timed out waiting for node to accept connections")
      end
      counter += 1
    end
    logger.debug("Finished waiting node to accept connections")
  end

  def cluster_replication_status
    nodes = node_ips.map do |node_ip|
      begin
        JSON.parse(HTTParty.get("http://#{node_ip}:63145/v1/replication_status",
                                basic_auth: webservice_credentials).body)
      rescue Exception
        logger.debug("Could not reach node: #{node_ip}")
        nil
      end
    end
    return nodes.select { |node| !node.nil? && node["status"] == "success" }
  end

  def all_standby_nodes_unblocked(tolerance = 120)
    min_age = standby_min_age
    cluster_nodes = cluster_replication_status
    logger.debug("Checking if whole cluster is accepting connections - " \
                 "cluster_nodes: #{cluster_nodes}")
    standby_nodes = cluster_nodes.select { |node| node["data"]["pg_mode"] == "standby" }

    standby_nodes.each do |node|
      pg_client = UnitTestsUtils::PostgreSQLClient.create_from_manifest(manifest, { host: node["data"]["node"]["ip"] })
      begin
        if pg_client.ping > 0

          if node["data"]["standby_age"] > min_age + tolerance
            raise Exception.new("Standby node is rejecting connection after tolerance time - " \
                              "tolerance: *#{min_age + tolerance}*, min_age: *#{min_age}*")
          end

          return false
        end
      rescue PG::ConnectionBad
        return false
      end
    end
    return true
  end

  def wait_standby_accept_connections(period = 5)
    logger.debug("Waiting all standby nodes reach minimum age.")
    while !all_standby_nodes_unblocked do
      sleep(period)
    end
    logger.debug("Finished waiting all standby nodes reach minimum age")
  end

  def cluster_is_sync
    wait_standby_accept_connections

    host = master_ip
    logger.debug("Checking if cluster has replicated the data - host: #{host}")
    pg_client = UnitTestsUtils::PostgreSQLClient.create_from_manifest(manifest, { host: host })
    res = pg_client.execute("SELECT pg_current_wal_lsn();", { dbname: "postgres" })

    master_lsn = lsn_to_i(res.values.flatten.first)

    standby_ips.each do |node|
      pg_client = UnitTestsUtils::PostgreSQLClient.create_from_manifest(manifest, { host: node })
      res = pg_client.execute("SELECT pg_last_wal_receive_lsn();", { dbname: "postgres" })

      standby_lsn = lsn_to_i(res.values.flatten.first)
      logger.debug("Master_lsn: (#{host}) - *#{master_lsn}*, Standby_lsn: (#{node}) - *#{standby_lsn}*")
      if standby_lsn < master_lsn
        return false
      end
    end
    return true
  end

  def wait_cluster_is_sync(period = 5, retries = 1200)
    logger.debug("Waiting cluster is synchonized.")
    counter = 0
    while ! cluster_is_sync do
      sleep(period)

      if counter >= retries
        raise Exception.new("Timed out waiting for cluster to replicate data")
      end
      counter += 1
    end
    logger.debug("Finished waiting cluster synchronization")
  end

  def is_cluster_stable
    logger.debug("Checking if cluster is stable")
    master = master_node

    logger.debug("Got master - master: #{master}")

    # Check if there is a master already
    return false if master["status"] != "succeeded"

    # Remove unreacheable nodes
    nodes = cluster_status.select do |node|
      node["status"] == "succeeded" if not node.nil?
    end

    logger.debug("Got online nodes - nodes: #{nodes}")

    # FIXME: This is bad, we should not remove the blocked nodes.
    nodes_accepting_connections = nodes.select do |node|
      !node["data"]["blocked"]
    end

    logger.debug("Nodes accepting connections - nodes_accepting_connections: #{nodes_accepting_connections}")

    # Check if all reacheable nodes are running and following the same master
    nodes_accepting_connections.each do |node|
      if node["data"]["failover_in_progress"] ||
          node["data"]["upstream_node_id"] != master["data"]["id"] ||
          node["data"]["status"] != "running"
        return false
      end
    end

    standby_nodes = nodes.select { |node| node["data"]["mode"] == "standby" }
    logger.debug("Standby nodes state - standby_nodes: *#{standby_nodes}*")
    standby_nodes.each do |standby_node|
      return false if standby_node["data"]["blocked"]
    end

    return true
  end

  def wait_failover(period = 5, retries = 1200)
    logger.debug("Waiting for failover to happen...")
    counter = 0
    while ! is_cluster_stable do
      sleep(period)

      if counter >= retries
        raise Exception.new("Timed out waiting for cluster to complete failover")
      end
      counter += 1
    end
    logger.debug("Finished waiting for failover to happen...")
  end

  def cluster_status
    nodes = node_ips.map do |node_ip|
      logger.debug("Node: #{node_ip}")
      begin
        JSON.parse(HTTParty.get("http://#{node_ip}:63145/v1/status", basic_auth: webservice_credentials).body)
      rescue Exception
        logger.debug("Could not reach node: #{node_ip}")
        nil
      end
    end
    nodes.select { |node| node != nil }
  end

  def is_cluster_ready
    logger.debug("Getting cluster status...")
    nodes_status = cluster_status
    logger.debug("Cluster status: #{nodes_status}")
    nodes = nodes_status.select { |node_status| node_status["status"] == "succeeded" && node_status["data"]["status"] == "running" }

    return nodes.length == nodes_status.length && has_a_master(nodes_status)
  end

  private

  def webservice_credentials
    {
      :username => "admin",
      :password => password
    }
  end

  def has_a_master(nodes)
    masters = nodes.select do |node|
      node["status"] == "succeeded" &&
      node["data"]["mode"] == "master" &&
      node["data"]["status"] == "running" &&
      node["data"]["id"] == node["data"]["upstream_node_id"] &&
      node["data"]["master_in_majority_partition"] == true
    end
    return masters.length > 0
  end

  def lsn_to_i(lsn)
    split_lsn = lsn.split("/")
    split_lsn[0].hex << 32 | split_lsn[1].hex
  end

end
