require 'json'
require 'httparty'
require 'open3'
require 'set'
require 'destructor'
require 'socket'
require 'timeout'

class UnitTestsUtils::Turbulence
  # URL should be i.e. https://IP:PORT/api/v1/incidents
  def initialize(logger)
    @logger = logger
    host = get_from_env('TURBULENCE_HOST')
    port = get_from_env_or_default('TURBULENCE_PORT', 8080)
    @url = "https://#{host}:#{port}/api/v1/incidents"
    @username = get_from_env('TURBULENCE_USER')
    @password = get_from_env('TURBULENCE_SECRET')
    @locked_instances = Set.new
  end

  # this will be called right before the GC cleans up an
  # object instance
  def finalize
    # below function is not yet fully functional
    unlock_all_instances
  end

  def get_vm_id(deployment, instance_jobname, instance_index)
    bosh_ids = get_bosh_ids(deployment)
    bosh_ids_sorted = {}
    bosh_ids.each do |id|
      jobname = id.split('/')[0].strip
      guid = id.split('/')[1].strip
      bosh_ids_sorted[jobname] = bosh_ids_sorted[jobname] || []
      bosh_ids_sorted[jobname].push(guid)
    end
    bosh_ids_sorted[instance_jobname][instance_index.to_i]
  end

  # deployment_name: should be a string
  # ids: an array of vm guid's
  # returns ID of the task in turbulence
  def crash_vms_without_blocking(deployment_name, ids: [])
    # below function is not yet fully functional
    # lock_instances(ids)
    body = {
      'Tasks' =>
                   [
                     { 'Type' => 'Shutdown', 'Crash' => true }
                   ]
    }
    body['Selector'] = get_vms_selector(deployment_name, ids: ids)
    send_post_request(body)
  end

  def crash_vms(deployment, ids: [])
    lock_instances(deployment, ids: ids)
    incident_id = crash_vms_without_blocking(deployment, ids: ids)
    block_until_crashed(deployment, ids: ids)
    incident_id
  end

  # Isolates the given VMs via IPtables, only SSH and Boshagent will still be
  # reachable
  # timeout: how long should the vm keep isolated, can be given in ms, s, m, h
  # TODO: Inactive since not implemented yet with blocking
  # def isolate_vms(deployment_name, timeout: "2m", ids: [])
  #   body = { "Tasks" =>
  #            [
  #              { "Type" => "Firewall", "Timeout" => "#{timeout}" }
  #            ]
  #          }
  #   body["Selector"] = get_vms_selector(deployment_name, ids: ids)
  #   return send_post_request(body)
  # end

  # performs a high load on given VMs
  # timeout: how long should the vm keep isolated, can be given in ms, s, m, h
  # stress is used to trigger the high load, take a look at the docu:
  # https://people.seas.harvard.edu/~apw/stress/
  # TODO: Inactive since not implemented yet with blocking
  # def stress_vms(deployment_name, timeout: "2m", numCPUWorkers: 1, numIOWorkers: 0, numMemoryWorkers: 0, memoryWorkerBytes: "", numHDDWorkers: 0, hddWorkerBytes: "", ids: [])
  #   raise NotImplementedError
  #   body = { "Tasks" =>
  #            [
  #              { "Type" => "Stress", "Timeout" => "#{timeout}",
  #                "NumCPUWorkers" => numCPUWorkers,
  #                "NumIOWorkers" => numIOWorkers,
  #                "NumMemoryWorkers" => numMemoryWorkers,
  #                "MemoryWorkerBytes" => "#{memoryWorkerBytes}",
  #                "NumHDDWorkers" => numHDDWorkers,
  #                "HDDWorkerBytes" => "#{hddWorkerBytes}"
  #              }
  #            ]
  #          }

  #   body["Selector"] = get_vms_selector(deployment_name, ids: ids)
  #   return send_post_request(body)
  # end

  # type should be one of "ephemeral", persistent, temporary or root
  # TODO: Inactive since not implemented yet with blocking
  # def filldisk_vms(deployment_name, type: "root", ids: [])
  #   raise NotImplementedError
  #   body = { "Tasks" =>
  #            [
  #              { "Type" => "FillDisk" }
  #            ]
  #          }

  #    case type
  #    when "ephemeral"
  #      body["Tasks"][0]["Ephemeral"] = true
  #    when "persistent"
  #      body["Tasks"][0]["Persistent"] = true
  #    when "temporary"
  #      body["Tasks"][0]["Temporary"] = true
  #    when "root"
  #      puts "nothing to do, filling root"
  #    else
  #      raise "given disktype not known"
  #    end

  #   body["Selector"] = get_vms_selector(deployment_name, ids: ids)
  #   return send_post_request(body)
  # end

  # type is either "loss" or "delay", it means packet loss or delay
  # amount is depending on loss or delay either the percentage of packets which
  # should get loss or the time in ms for the delay of packets
  # TODO: Inactive since not implemented yet with blocking
  # def network_trouble_vms(deployment_name, timeout: "2m", type: "loss", amount: 100, ids: [])
  #   raise NotImplementedError
  #   body = { "Tasks" =>
  #            [
  #              { "Type" => "ControlNet", "Timeout" => "#{timeout}" }
  #            ]
  #          }

  #   case type
  #   when "loss"
  #     body["Tasks"][0]["Delay"] = "#{amount}ms"
  #   when "delay"
  #     body["Tasks"][0]["Loss"] = "#{amount}%"
  #   else
  #     raise "no valid network trouble type given"
  #   end

  #   body["Selector"] = get_vms_selector(deployment_name, ids: ids)
  #   return send_post_request(body)
  # end

  # processname is the name or regex of a process which should be killed
  # this name is related to the name of the monit processname
  # TODO: Inactive since not implemented yet with blocking
  # def kill_process_on_vms(deployment_name, processname, ids: [])
  #   body = { "Tasks" =>
  #            [
  #              { "Type" => "KillProcess", "MonitoredProcessName" => "#{processname}" }
  #            ]
  #          }

  #   body["Selector"] = get_vms_selector(deployment_name, ids: ids)
  #   return send_post_request(body)
  # end

  # getting the status of an incident
  def get_incident_status(id)
    raise NotImplementedError
    response = HTTParty.get(
      "#{url.to_str}/:#{id}",
      headers: { 'Content-Type' => 'application/json' },
      basic_auth: auth,
      verify: false
    )
    raise "Request to turbulence(#{url.to_str}/:#{id}) failed" unless response.success?

    JSON.parse(response.body)
  end

  def start_vms(deployment, ids: [], port: nil)
    unlock_instances_and_block_until_running(deployment, ids: ids, port: port)
  end

  private

  attr_reader :url, :username, :password, :logger

  # executes the given function against turbulence
  # raisess error if request fails
  # returns job ID if request is fine
  def send_post_request(body)
    response = HTTParty.post(
      url.to_str,
      body: body.to_json,
      headers: { 'Content-Type' => 'application/json' },
      basic_auth: auth,
      verify: false
    )

    logger.debug(
      "POST Request to Turbulence: \n" \
      "\tURL: #{url.to_str}\n" \
      "\tAUTH: #{auth}\n" \
      "\tBODY: #{body.to_json}"
    )

    unless response.success?
      raise "Request to turbulence(#{url.to_str}) failed, \n" \
            "\tauth: #{auth.inspect}, \n" \
            "\tBody: #{body}, \n" \
            "\tResponse: #{response.body}"
    end
    response_body = JSON.parse(response.body)
    response_body['ID']
  end

  # deployment_name: should be a string
  # ids: an array of vm guid's
  def get_vms_selector(deployment_name, ids: [])
    {
      'Deployment' => {
        'Name' => deployment_name,
        'Limit' => '100%'
      },
      'ID' => { 'Values' => ids }
    }
  end

  def auth
    { username: username.to_s, password: password.to_s }
  end

  def get_from_env(name)
    raise "ENV variable '#{name}' required!" unless ENV[name]

    ENV[name]
  end

  def get_from_env_or_default(name, default)
    @logger.debug "ENV variable '#{name}' not found! Defaulting to: #{default}" unless ENV[name]
    ENV[name] || default
  end

  def get_ips_for_deployment(deployment, ids: [])
    wanted_ip_addresses = []
    if ids == []
      wanted_ip_addresses = `bosh vms -d #{deployment} | awk '{print $4}'`.split
    else
      vms = `bosh vms -d #{deployment} | sed 's/unresponsive agent/unresponsive_agent/'`
      ids_of_vms = `echo '#{vms}' | awk '{print $1}' | sed 's|.*/||'`.split
      ip_addresses_of_vms = `echo '#{vms}' | awk '{print $4}'`.split
      ids_of_vms.zip(ip_addresses_of_vms).each do |current_id, current_ip_address|
        wanted_ip_addresses.push(current_ip_address) if ids.include? current_id
      end
    end
    wanted_ip_addresses
  end

  def lock_instances(deployment, ids: [])
    ids = fix_ids_for_bosh(deployment, ids: ids)
    ids.each do |id|
      puts("bosh ignore -d #{deployment} #{id}")
      `bosh ignore -d '#{deployment}' '#{id}'`
      @locked_instances.add([deployment, id])
    end
  end

  def unlock_instances(deployment, ids: [])
    @logger.debug('unignoring instances')
    ids = fix_ids_for_bosh(deployment, ids: ids)
    @logger.debug(ids.inspect.to_s)
    ids.each do |id|
      @logger.debug("bosh unignore -d #{deployment} #{id}")
      result = `bosh unignore -d '#{deployment}' '#{id}'`
      @logger.debug(result.inspect.to_s)
      @locked_instances.delete([deployment, id])
    end
  end

  def unlock_instances_and_block_until_running(deployment, ids: [], port: nil)
    unlock_instances(deployment, ids: ids)
    block_until_recreated(deployment, ids: ids, port: port)
  end

  def unlock_all_instances
    @locked_instances.each do |deployment, id|
      `bosh unignore -d '#{deployment}' '#{id}'`
    end
    @locked_instances.clear
  end

  def get_bosh_ids(deployment)
    bosh_vms = `bosh vms -d '#{deployment}'`
    bosh_ids = []
    bosh_vms.split("\n").each do |line|
      bosh_ids.push(line.split("\t")[0].strip)
    end
    bosh_ids
  end

  # This transforms IDs suitable for Turbulence into the format BOSH understands
  # Other than all other functions, this function handles ids being empty in a
  # special way. This is because when an empty array is passed to Turbulence it
  # assumes all instances shall be affected whereas BOSH needs to informed about
  # every single instance. So introducing this inconsistency makes all functions
  # regarding BOSH consistent with Turbulence's behavior
  def fix_ids_for_bosh(deployment, ids: [])
    fixed_ids = []
    bosh_ids = get_bosh_ids(deployment)
    if ids.empty?
      fixed_ids = bosh_ids
    else
      bosh_ids.each do |id|
        search_term = id.split('/')[1].strip
        fixed_ids.push(id) if ids.find { |e| search_term == e }
      end
    end
    fixed_ids
  end

  def block_until_crashed(deployment, ids: [])
    addresses = get_ips_for_deployment(deployment, ids: ids)
    pings_successful = true
    loopcounter = 0
    while pings_successful
      sleep 5
      ping_statuses = []
      addresses.each do |ip|
        _, __, status = Open3.capture3('ping', '-c', '1', ip)
        @logger.debug "Pinged #{ip} with status #{status.exitstatus}"
        ping_statuses.push(status.success?)
      end
      pings_successful = ping_statuses.reduce(:|)
      loopcounter += 1
      raise 'pinged instances 100 times without detecting expected crashes, aborting...' if loopcounter == 100
    end
  end

  def block_until_recreated(deployment, ids: [], port: nil)
    addresses = get_ips_for_deployment(deployment, ids: ids)
    pings_successful = false
    loopcounter = 0
    until pings_successful
      sleep 5
      ping_statuses = []
      addresses.each do |ip|
        _, __, status = Open3.capture3('ping', '-c', '1', ip)
        @logger.debug "Pinged #{ip} with status #{status.exitstatus}"
        ping_statuses.push(status.success?)
      end
      pings_successful = ping_statuses.reduce(:&)
      loopcounter += 1
      # waiting ~30 minutes should suffice for a cluster of three instances to come up
      raise 'pinged instances 360 times without success, aborting...' if loopcounter == 360
    end

    ports_open = false
    ports_open = true if port.nil?
    loopcounter = 0
    until ports_open
      sleep 5
      port_statuses = []
      addresses.each do |ip|
        port_status = is_port_open?(ip, port)
        @logger.debug "Open port #{port} on IP #{ip} is #{port_status}"
        port_statuses.push(port_status)
      end

      ports_open = port_statuses.reduce(:&)
      loopcounter += 1
      # waiting ~30 minutes should suffice for a cluster of three instances to come up
      raise 'checked ports of instances 360 times without success, aborting...' if loopcounter == 360
    end
  end

  def is_port_open?(ip, port)
    begin
      Timeout.timeout(1) do
        s = TCPSocket.new(ip, port)
        s.close
        return true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return false
      end
    rescue Timeout::Error
    end

    false
  end
end
