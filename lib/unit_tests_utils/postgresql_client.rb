require 'pg'
require 'securerandom'

class UnitTestsUtils::PostgreSQLClient
  attr_reader :args

  POSTGRESQL_PROPERTIES_PATH = '/instance_groups/name=pg/jobs/name=postgresql-ha/properties'.freeze
  TEST_TABLE = 'a9s_pg_tests'.freeze

  def self.create_from_manifest(manifest, args = {})
    args[:host] ||= manifest.hostname
    args[:user] ||= manifest.properties['postgresql-ha']['admin_credentials']['username']
    args[:password] ||= manifest.properties['postgresql-ha']['admin_credentials']['password']

    args[:sslmode] = 'require' if manifest.properties("#{POSTGRESQL_PROPERTIES_PATH}/postgresql-ha/ssl?/enable")

    new(args)
  end

  def initialize(args)
    @args = args
    @args[:dbname] ||= 'area51'
    @args[:sslmode] ||= 'disable'
  end

  def ping(extra_args = {})
    ping_args = args.merge(extra_args)
    logger.debug("* Creating ping with args: *#{ping_args}*")
    PG::Connection.ping(ping_args)
  end

  def drop_table
    execute("DROP TABLE IF EXISTS #{TEST_TABLE}")
  end

  def create_table
    execute(
      "CREATE TABLE IF NOT EXISTS #{TEST_TABLE} (test_key TEXT PRIMARY KEY NOT NULL, " \
                  'test_value TEXT NOT NULL)'
    )
  end

  def generate_data
    { 'test_key' => SecureRandom.uuid.to_s, 'test_value' => SecureRandom.uuid.to_s }
  end

  def insert(data)
    execute("INSERT INTO #{TEST_TABLE} VALUES ('#{data['test_key']}', '#{data['test_value']}')")
  end

  def replication_slots
    execute('SELECT * FROM pg_replication_slots;')
  end

  def select(data, args = {})
    execute("SELECT test_key, test_value FROM #{TEST_TABLE} WHERE test_key = '#{data['test_key']}'", args)
  end

  def max_connections
    execute('SHOW max_connections')[0]['max_connections'].to_i
  end

  def data_checksums?
    execute('SHOW data_checksums')[0]['data_checksums'] == 'on'
  end

  def database(database_name)
    execute("SELECT 1 FROM pg_database WHERE datname = '#{database_name}'").map { |database| database['datname'] }
  end

  def work_mem
    execute('SHOW work_mem')[0]['work_mem'].to_i
  end

  def extensions
    execute('SELECT extname FROM pg_extension').map { |extension| extension['extname'] }
  end

  def connect(extra_args = {})
    connect_args = args.merge(extra_args)
    logger.debug("* Creating connection with args: *#{connect_args}*")
    PG::Connection.new(connect_args)
  end

  def execute(sql, args = {})
    conn = connect(args)
    conn.exec(sql)
  ensure
    conn&.close
  end
end
