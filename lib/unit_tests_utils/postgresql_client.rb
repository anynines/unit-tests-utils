require 'pg'

class UnitTestsUtils::PostgreSQLClient
  attr_reader :args

  POSTGRESQL_PROPERTIES_PATH = '/instance_groups/name=pg/jobs/name=postgresql-ha/properties'

  def initialize(args)
    @args = args
    @args[:dbname] ||= 'area51'
    @args[:sslmode] ||= 'disable'
  end

  def self.create_from_manifest(manifest, host = nil)
    host = manifest.hostname unless host
    user = manifest.properties['postgresql-ha']['admin_credentials']['username']
    password = manifest.properties['postgresql-ha']['admin_credentials']['password']
    if manifest.properties("#{POSTGRESQL_PROPERTIES_PATH}/postgresql-ha/ssl?/enable")
      sslmode = "require"
    end

    self.new(host: host, user: user, password: password, sslmode: sslmode)
  end

  def ping
    logger.debug("* Creating ping with args: *#{args}*")
    return PG::Connection.ping(args)
  end

  def connect(extra_args = {})
    args.merge!(extra_args)
    logger.debug("* Creating connection with args: *#{args}*")
    return PG::Connection.new(args)
  end

  def execute(sql, args = {})
    conn = connect(args)
    return conn.exec(sql)
  ensure
    conn.close if !conn.nil?
  end
end
