require 'pg'
require 'securerandom'

class UnitTestsUtils::PostgreSQLClient
  attr_reader :args

  POSTGRESQL_PROPERTIES_PATH = '/instance_groups/name=pg/jobs/name=postgresql-ha/properties'
  TEST_TABLE = 'a9s_pg_tests'.freeze

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

  def create_table
    execute("CREATE TABLE IF NOT EXISTS #{TEST_TABLE} (test_key TEXT PRIMARY KEY NOT NULL, " \
            "test_value TEXT NOT NULL)")
  end

  def generate_data
    {'test_key' => "#{SecureRandom.uuid}", 'test_value' => "#{SecureRandom.uuid}"}
  end

  def insert(data)
    execute("INSERT INTO #{TEST_TABLE} VALUES ('#{data['test_key']}', '#{data['test_value']}')")
  end

  def replication_slots
    execute('SELECT * FROM pg_replication_slots;')
  end

  def select(key, args = {})
    execute("SELECT test_key, test_value FROM #{TEST_TABLE} WHERE test_key = '#{key}'", args)
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
