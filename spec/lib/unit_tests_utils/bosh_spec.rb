require 'spec_helper'

describe UnitTestsUtils::Bosh do
  let(:deployment_name) { 'database-ha' }
  let(:manifest_path)   { './database-ha.yml' }
  let(:instance_name)   { 'database' }
  let(:release_name)    { 'release_name' }
  let(:release_version) { '0+dev.1' }
  let(:bosh_error_messages) do
    {
      create_release: 'Creating release failed',
      delete_deployment: 'Delete deployment failed',
      delete_release: 'Delete release failed',
      deploy: 'Deploy failed',
      instances: 'Instance status failed',
      ssh: 'Cannot execute command ',
      interpolate: 'Interpolate failed',
      start: 'Starting instance failed',
      stop: 'Stopping instance failed',
      task: 'Cannot wait for task to finish',
      upload_release: 'Uploading release failed'
    }
  end

  describe '.deploy' do
    let(:path_to_creds) { './config.yml' }
    let(:path_to_iaas_config) { './iaas_config.yml' }
    let(:additional_vars) { { key1: 'value1', key2: 'value2' } }
    let(:additional_ops_files) { ['ops-file-1', 'ops-file-2'] }
    let(:additional_vars_string) { additional_vars.map { |key, value| "--var #{key}='#{value}'" }.join(' ') }
    let(:additional_ops_files_string) do
      additional_ops_files.map { |file| "--ops-file #{file}" }.join(' ')
    end

    before do
      expect(ENV).to receive(:[]).with('PATH_TO_IAAS_CONFIG').at_least(:once)
        .and_return(path_to_iaas_config)
    end

    context 'when the PATH_TO_CREDS env var is set' do
      before do
        expect(ENV).to receive(:[]).with('PATH_TO_CREDS').at_least(:once)
          .and_return(path_to_creds)
      end

      context 'when NO additional vars are given' do
        it 'runs a bosh deployment' do
          expect(described_class).to receive(:execute_or_raise_error).once
            .with("bosh --non-interactive -d #{deployment_name} deploy -l #{ENV['PATH_TO_IAAS_CONFIG']} -l #{ENV['PATH_TO_CREDS']} #{manifest_path}", bosh_error_messages[:deploy])
            .and_return(nil)
          expect(described_class).to receive(:`).once
            .with("bosh -d #{deployment_name} task > /dev/null 2>&1")

          described_class.deploy(deployment_name, manifest_path)
        end
      end

      context 'when additional vars are given' do
        it 'runs a bosh deployment' do
          expect(described_class).to receive(:execute_or_raise_error).once
            .with("bosh --non-interactive -d #{deployment_name} deploy -l #{ENV['PATH_TO_IAAS_CONFIG']} -l #{ENV['PATH_TO_CREDS']} #{additional_vars_string} #{manifest_path}", bosh_error_messages[:deploy])
            .and_return(nil)
          expect(described_class).to receive(:`).once
            .with("bosh -d #{deployment_name} task > /dev/null 2>&1")

          described_class.deploy(deployment_name, manifest_path, additional_vars)
        end
      end

      context 'when additional ops files are given' do
        it 'runs a bosh deployment' do
          expect(described_class).to receive(:execute_or_raise_error).once
            .with("bosh --non-interactive -d #{deployment_name} deploy " \
                 "-l #{ENV['PATH_TO_IAAS_CONFIG']} -l #{ENV['PATH_TO_CREDS']} " \
                 "#{additional_vars_string} #{additional_ops_files_string} #{manifest_path}",
                  bosh_error_messages[:deploy])
            .and_return(nil)
          expect(described_class).to receive(:`).once
            .with("bosh -d #{deployment_name} task > /dev/null 2>&1")

          described_class.deploy(
            deployment_name,
            manifest_path,
            additional_vars,
            additional_ops_files
          )
        end
      end
    end

    context 'when the PATH_TO_CREDS env var is not set' do
      before do
        expect(ENV).to receive(:[]).with('PATH_TO_CREDS')
          .and_return(nil)
      end

      context 'when NO additional vars are given' do
        it 'runs a bosh deployment' do
          expect(described_class).to receive(:execute_or_raise_error).once
            .with("bosh --non-interactive -d #{deployment_name} deploy -l #{ENV['PATH_TO_IAAS_CONFIG']} #{manifest_path}", bosh_error_messages[:deploy])
            .and_return(nil)
          expect(described_class).to receive(:`).once
            .with("bosh -d #{deployment_name} task > /dev/null 2>&1")

          described_class.deploy(deployment_name, manifest_path)
        end
      end

      context 'when additional vars are given' do
        it 'runs a bosh deployment' do
          expect(described_class).to receive(:execute_or_raise_error).once
            .with("bosh --non-interactive -d #{deployment_name} deploy -l #{ENV['PATH_TO_IAAS_CONFIG']} #{additional_vars_string} #{manifest_path}", bosh_error_messages[:deploy])
            .and_return(nil)
          expect(described_class).to receive(:`).once
            .with("bosh -d #{deployment_name} task > /dev/null 2>&1")

          described_class.deploy(deployment_name, manifest_path, additional_vars)
        end
      end

      context 'when additional ops files are given' do
        it 'runs a bosh deployment' do
          expect(described_class).to receive(:execute_or_raise_error).once
            .with("bosh --non-interactive -d #{deployment_name} deploy " \
                 "-l #{ENV['PATH_TO_IAAS_CONFIG']} " \
                 "#{additional_vars_string} #{additional_ops_files_string} #{manifest_path}",
                  bosh_error_messages[:deploy])
            .and_return(nil)
          expect(described_class).to receive(:`).once
            .with("bosh -d #{deployment_name} task > /dev/null 2>&1")

          described_class.deploy(
            deployment_name,
            manifest_path,
            additional_vars,
            additional_ops_files
          )
        end
      end
    end
  end

  describe '.delete_deployment' do
    it 'runs a bosh delete-deployment' do
      expect(described_class).to receive(:execute_or_raise_error).once
        .with("bosh --non-interactive -d #{deployment_name} delete-deployment --force", bosh_error_messages[:delete_deployment])
      expect(described_class).to receive(:`).once
        .with("bosh -d #{deployment_name} task > /dev/null 2>&1")

      described_class.delete_deployment(deployment_name)
    end
  end

  describe '.start_instance' do
    context 'when the index is given' do
      let(:index) { 1 }

      it 'runs a bosh start on the given instance and index' do
        expect(described_class).to receive(:execute_or_raise_error).once
          .with("bosh --non-interactive -d #{deployment_name} start #{instance_name}/#{index}", bosh_error_messages[:start])
        expect(described_class).to receive(:`).once
          .with("bosh -d #{deployment_name} task > /dev/null 2>&1")

        described_class.start_instance(deployment_name, instance_name, index)
      end
    end

    context 'when the index is not given' do
      it 'runs a bosh start on the given instance with index 0' do
        expect(described_class).to receive(:execute_or_raise_error).once
          .with("bosh --non-interactive -d #{deployment_name} start #{instance_name}/0", bosh_error_messages[:start])
        expect(described_class).to receive(:`).once
          .with("bosh -d #{deployment_name} task > /dev/null 2>&1")

        described_class.start_instance(deployment_name, instance_name)
      end
    end
  end

  describe '.stop_instance' do
    context 'when the index is given' do
      let(:index) { 1 }

      it 'runs a bosh stop on the given instance and index' do
        expect(described_class).to receive(:execute_or_raise_error).once
          .with("bosh --non-interactive -d #{deployment_name} stop #{instance_name}/#{index}", bosh_error_messages[:stop])
        expect(described_class).to receive(:`).once
          .with("bosh -d #{deployment_name} task > /dev/null 2>&1")

        described_class.stop_instance(deployment_name, instance_name, index)
      end
    end

    context 'when the index is not given' do
      it 'runs a bosh stop on the given instance with index 0' do
        expect(described_class).to receive(:execute_or_raise_error).once
          .with("bosh --non-interactive -d #{deployment_name} stop #{instance_name}/0", bosh_error_messages[:stop])
        expect(described_class).to receive(:`).once
          .with("bosh -d #{deployment_name} task > /dev/null 2>&1")

        described_class.stop_instance(deployment_name, instance_name)
      end
    end
  end

  describe '.run_errand' do
    let(:errand_name) { 'myerrand' }

    context 'when deployment name and errand name is given' do
      it 'runs the errand' do
        expect(described_class).to receive(:execute_or_raise_error).once
          .with("bosh --non-interactive -d #{deployment_name} run-errand #{errand_name}",
                "Failed to run errand #{errand_name}")
          .and_return(nil)

        expect(described_class).to receive(:`).once
          .with("bosh -d #{deployment_name} task > /dev/null 2>&1")

        described_class.run_errand(deployment_name, errand_name)
      end
    end
  end

  describe '.create_and_upload_dev_release' do
    let(:base_dir) { './' }
    let(:release_path) { File.join(base_dir, 'dev_releases', release_name, "#{release_name}-#{release_version}.yml") }
    let(:metadata) do
      {
        unit_test_name: "#{release_name}-#{release_version.gsub('.', '-')}",
        unit_test_release_name: release_name,
        unit_test_release_version: release_version,
        unit_test_release_commit_hash: '4a207a6+'
      }
    end

    it 'runs a bosh create-release and upload-release' do
      allow(described_class).to receive(:dev_release_version).and_return(release_version)

      expect(described_class).to receive(:execute_or_raise_error).once
        .with("bosh --json create-release --dir #{base_dir} --name #{release_name} --version " \
             "#{release_version} --force",
              bosh_error_messages[:create_release])
        .and_return(bosh_release_output(release_name, release_version))
      expect(described_class).to receive(:execute_or_raise_error).once
        .with("bosh upload-release --dir #{base_dir} #{release_path}", bosh_error_messages[:upload_release])

      expect(described_class.create_and_upload_dev_release(base_dir, release_name)).to eq metadata
    end
  end

  def bosh_release_output(release_name, release_version)
    raw_json = Fixtures.file_content('bosh-create-release-output.json')
    json = JSON.parse(raw_json)

    json['Tables'][0]['Rows'][0]['name'] = release_name
    json['Tables'][0]['Rows'][0]['version'] = release_version

    json.to_json
  end

  describe '.delete_release' do
    it 'runs a bosh delete-release' do
      expect(described_class).to receive(:execute_or_raise_error).once
        .with("bosh --non-interactive delete-release #{release_name}", bosh_error_messages[:delete_release])

      described_class.delete_release(release_name)
    end
  end

  describe '.ssh' do
    let(:command) { 'ls' }

    context 'when an instance name is given' do
      context 'when an index is given' do
        let(:index) { '1' }

        it 'runs bosh ssh' do
          expect(described_class).to receive(:execute_or_raise_error).once
            .with("bosh -d #{deployment_name} ssh #{instance_name}/#{index} -c '#{command}'", bosh_error_messages[:ssh] + command)

          described_class.ssh(deployment_name, command, instance_name, index)
        end
      end

      context 'when the index is not given' do
        it 'runs bosh ssh' do
          expect(described_class).to receive(:execute_or_raise_error).once
            .with("bosh -d #{deployment_name} ssh #{instance_name}/0 -c '#{command}'", bosh_error_messages[:ssh] + command)

          described_class.ssh(deployment_name, command, instance_name)
        end
      end
    end

    context 'when no instance is given' do
      it 'runs bosh ssh' do
        expect(described_class).to receive(:execute_or_raise_error).once
          .with("bosh -d #{deployment_name} ssh -c '#{command}'", bosh_error_messages[:ssh] + command)

        described_class.ssh(deployment_name, command)
      end
    end
  end

  describe '.interpolate' do
    let(:path_to_creds) { Fixtures.file_path 'creds.yml' }
    let(:path_to_iaas_config) { Fixtures.file_path 'iaas_config.yml' }
    let(:additional_vars) { { key1: 'value1', key2: 'value2' } }
    let(:additional_vars_string) { additional_vars.map { |key, value| "--var #{key}='#{value}'" }.join(' ') }

    context 'when the PATH_TO_CREDS env var is set' do
      before do
        stubbed_env = ENV.to_h
        stubbed_env['PATH_TO_IAAS_CONFIG'] = path_to_iaas_config
        stubbed_env['PATH_TO_CREDS'] = path_to_creds
        stub_const('ENV', stubbed_env)
      end

      context 'when NO additional vars are given' do
        it 'interpolates a deployment manifest' do
          expect(described_class).to receive(:execute_or_raise_error).once
            .with("bosh interpolate -l #{ENV['PATH_TO_IAAS_CONFIG']} -l #{ENV['PATH_TO_CREDS']} #{manifest_path}", bosh_error_messages[:interpolate])

          described_class.interpolate(manifest_path)
        end
      end

      context 'when additional vars are given' do
        it 'interpolates a deployment manifest' do
          expect(described_class).to receive(:execute_or_raise_error).once
            .with("bosh interpolate -l #{ENV['PATH_TO_IAAS_CONFIG']} -l #{ENV['PATH_TO_CREDS']} #{additional_vars_string} #{manifest_path}", bosh_error_messages[:interpolate])

          described_class.interpolate(manifest_path, additional_vars)
        end
      end

      context 'when additional ops-files are given' do
        let(:ops_files) { ['/tmp/dummy-ops.yml', '/tmp/dummy-ops-2.yml'] }
        let(:ops_files_string) { ops_files.map { |file| "--ops-file #{file}" }.join(' ') }

        it 'interpolates a deployment manifest' do
          expect(described_class).to receive(:execute_or_raise_error).once
            .with("bosh interpolate -l #{ENV['PATH_TO_IAAS_CONFIG']} -l #{ENV['PATH_TO_CREDS']} " \
                 "#{additional_vars_string} #{ops_files_string} #{manifest_path}",
                  bosh_error_messages[:interpolate])

          described_class.interpolate(manifest_path, additional_vars, false, ops_files)
        end
      end
    end

    context 'when the PATH_TO_CREDS env var is not set' do
      before do
        stubbed_env = ENV.to_h
        stubbed_env['PATH_TO_IAAS_CONFIG'] = path_to_iaas_config
        stubbed_env['PATH_TO_CREDS'] = nil
        stub_const('ENV', stubbed_env)
      end

      context 'when NO additional vars are given' do
        it 'interpolates a deployment manifest' do
          expect(described_class).to receive(:execute_or_raise_error).once
            .with("bosh interpolate -l #{ENV['PATH_TO_IAAS_CONFIG']} #{manifest_path}", bosh_error_messages[:interpolate])

          described_class.interpolate(manifest_path)
        end
      end

      context 'when additional vars are given' do
        it 'interpolates a deployment manifest' do
          expect(described_class).to receive(:execute_or_raise_error).once
            .with("bosh interpolate -l #{ENV['PATH_TO_IAAS_CONFIG']} #{additional_vars_string} #{manifest_path}", bosh_error_messages[:interpolate])

          described_class.interpolate(manifest_path, additional_vars)
        end
      end
    end
  end

  describe '.instance_status' do
    context 'when the index is not given' do
      it 'runs a bosh instance' do
        expect(described_class).to receive(:execute_or_raise_error).once
          .with("bosh --non-interactive -d #{deployment_name} instances --details --json", bosh_error_messages[:instances])
          .and_return(Fixtures.file_content('bosh-instances-details-output.json'))

        result = described_class.instance_status(deployment_name, instance_name)
        expect(result.length).to eq(3)
      end
    end

    context 'when the index is given' do
      it 'runs a bosh instance' do
        expect(described_class).to receive(:execute_or_raise_error).once
          .with("bosh --non-interactive -d #{deployment_name} instances --details --json", bosh_error_messages[:instances])
          .and_return(Fixtures.file_content('bosh-instances-details-output.json'))

        result = described_class.instance_status(deployment_name, instance_name, '0')
        expect(result.length).to eq(1)
        expect(result.first['index']).to eq('0')
      end
    end

    context 'when bosh is unavailable' do
      it 'raises an exception' do
        expect(described_class).to receive(:execute_or_raise_error).once
          .with("bosh --non-interactive -d #{deployment_name} instances --details --json", bosh_error_messages[:instances])
          .and_return(Fixtures.file_content('bosh-instances-ps-error.json'))

        expect do
          described_class.instance_status(deployment_name, instance_name)
        end.to raise_error(Exception, "Could not find 'Tables'. Maybe this is a request timeout.")
      end
    end

    context 'when bosh gives an invalid json as response' do
      it 'raises a json exception' do
        expect(described_class).to receive(:execute_or_raise_error).once
          .with("bosh --non-interactive -d #{deployment_name} instances --details --json", bosh_error_messages[:instances])
          .and_return(Fixtures.file_content('bosh-invalid-json-output.json'))

        expect do
          described_class.instance_status(deployment_name, instance_name)
        end.to raise_error(JSON::ParserError)
      end
    end
  end

  describe '.execute_or_raise_error' do
    context 'when the command returns a zero status' do
      it "returns the command's stdout" do
        return_message = ''
        raises_error = false
        begin
          return_message = described_class.execute_or_raise_error('echo myteststring', 'this is not meant to fail')
        rescue UnitTestsUtils::Bosh::BoshError => _e
          raises_error = true
        end
        expect(return_message).to eql("myteststring\n")
        expect(raises_error).to be_falsy
      end
    end

    context 'when the command returns a non-zero status' do
      it 'raises a BOSH exception with error message' do
        raises_error = false
        begin
          described_class.execute_or_raise_error('/usr/bin/env false', 'this is meant to fail')
        rescue UnitTestsUtils::Bosh::BoshError => e
          expect(e.message).to match(/this is meant to fail - exit_status: pid [0-9]+ exit 1\s*stdout:\s*stderr:\s*/)
          raises_error = true
        end
        expect(raises_error).to be_truthy
      end
    end
  end
end
