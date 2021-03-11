require 'spec_helper'

describe UnitTestsUtils::PostgreSQLClient do
  let(:test_table) { UnitTestsUtils::PostgreSQLClient::TEST_TABLE }
  let(:args) do
    {
      host: 'dummyhost',
      sslmode: 'require',
    }
  end

  subject(:client) { UnitTestsUtils::PostgreSQLClient.new(args) }

  describe '#new' do
    context 'when new args are given' do

      it 'is applied to the client' do
        expect(client.args[:host]).to eq(args[:host])
        expect(client.args[:sslmode]).to eq(args[:sslmode])
      end

      it 'specifies some defaults' do
        expect(client.args[:dbname]).to eq('area51')
      end
    end
  end

  describe '#drop_table' do
    it 'drops a table if it exists' do
      expect(client).to receive(:execute).
        with("DROP TABLE IF EXISTS #{test_table}").and_return(PG::Result.new()).once

      expect(client.drop_table).to be_a(PG::Result)
      end
  end

  describe '#create_table' do
    it 'creates a table with the default name' do
      expect(client).to receive(:execute).
        with("CREATE TABLE IF NOT EXISTS #{test_table} (test_key TEXT PRIMARY KEY NOT NULL, " \
           "test_value TEXT NOT NULL)").and_return(PG::Result.new()).once

      expect(client.create_table).to be_a(PG::Result)
      end
  end

  describe '#generate_data' do
    it 'generates random data' do
      data = client.generate_data
      expect(data['test_key']).to be_a(String)
      expect(data['test_value']).to be_a(String)
    end
  end

  describe '#insert' do
    let(:data) { { 'test_key' => 'dummy_key', 'test_value' => 'dummy_value'} }

    it 'executes create table if not exists and inserts data' do
      expect(client).to receive(:execute).
        with("INSERT INTO #{test_table} VALUES ('#{data['test_key']}', '#{data['test_value']}')").
        and_return(PG::Result.new()).once

      expect(client.insert(data)).to_not be_nil
    end
  end

  describe '#select' do
    let(:test_key) { 'dummy_key' }
    let(:data) { client.generate_data }

    context 'when no args are given' do
      it 'selects with default args' do
        expect(client).to receive(:execute).
          with("SELECT test_key, test_value FROM #{test_table} WHERE test_key = '#{data['test_key']}'", {}).
          and_return(PG::Result.new()).once

        expect(client.select(data)).to_not be_nil
      end
    end

    context 'when args are given' do
      let(:args) { { host: 'other_dummy_host' } }

      it 'passes the args to the client' do
        expect(client).to receive(:execute).
          with("SELECT test_key, test_value FROM #{test_table} WHERE test_key = '#{data['test_key']}'", args).
          and_return(PG::Result.new()).once

        expect(client.select(data, args)).to_not be_nil
      end
    end
  end

  describe '#replication_slots' do
    it 'lists the replication slots' do
      expect(client).to receive(:execute).
        with('SELECT * FROM pg_replication_slots;').
        and_return(PG::Result.new()).once

      expect(client.replication_slots).to_not be_nil
    end
  end

  describe '#max_connections' do
    it 'get max connections value' do
      max_connections_expected = 10
      expect(client).to receive(:execute).
          with('SHOW max_connections').
          and_return(['max_connections' => max_connections_expected.to_s]).once

      expect(client.max_connections).to eq(max_connections_expected)
    end
  end

  describe '#data_checksums?' do
    it 'get data checksum value as true' do
      expect(client).to receive(:execute).
          with('SHOW data_checksums').
          and_return(['data_checksums' => 'on']).once

      expect(client.data_checksums?).to eq(true)
    end

    it 'get data checksum value as false' do
      expect(client).to receive(:execute).
          with('SHOW data_checksums').
          and_return(['data_checksums' => 'anything']).once

      expect(client.data_checksums?).to eq(false)
    end
  end

  describe '#database' do
    it 'get databases' do
      database_name = 'database_name'
      expect(client).to receive(:execute).
          with("SELECT 1 FROM pg_database WHERE datname = '#{database_name}'").
          and_return(['datname' => database_name]).once

      expect(client.database(database_name).size).to eq(1)
    end
  end

  describe '#work_mem' do
    it 'get work memory value' do
      work_mem_expected = 8
      expect(client).to receive(:execute).
          with('SHOW work_mem').
          and_return(['work_mem' => work_mem_expected.to_s]).once

      expect(client.work_mem).to eq(work_mem_expected)
    end
  end

  describe '#extensions' do
    it 'get extensions' do
      extname_expected = 'extname'
      expect(client).to receive(:execute).
          with('SELECT extname FROM pg_extension').
          and_return(['extname' => extname_expected]).once

      expect(client.extensions[0]).to eq(extname_expected)
    end
  end
end
