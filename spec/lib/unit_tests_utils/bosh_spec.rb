require 'spec_helper'
require 'json'
require_relative '../../../lib/unit_tests_utils'

describe UnitTestsUtils::Bosh do
  let(:deployment_name) { "database-ha" }
  let(:manifest_path)   { "./database-ha.yml" }
  let(:instance_name)   { "database" }
  let(:release_name)    { "release_name" }
  let(:release_version) { "0+dev.1" }

  describe ".deploy" do
    let(:path_to_creds) { './config.yml' }
    let(:path_to_iaas_config) { './iaas_config.yml' }
    let(:additional_vars) { { key1: 'value1', key2: 'value2' } }
    let(:additional_vars_string) { additional_vars.map { |key, value| "--var #{key}=#{value}" }.join(' ') }

    before :each do
      expect(ENV).to receive(:[]).with('PATH_TO_IAAS_CONFIG').at_least(:once).
        and_return(path_to_iaas_config)
    end

    context "when the PATH_TO_CREDS env var is set" do
      before :each do
        expect(ENV).to receive(:[]).with('PATH_TO_CREDS').at_least(:once).
          and_return(path_to_creds)
      end

      context "when NO additional vars are given" do
        it "runs a bosh deployment" do
          expect(UnitTestsUtils::Bosh).to receive(:`).once.
            with("bosh --non-interactive -d #{deployment_name} deploy -l #{ENV['PATH_TO_IAAS_CONFIG']} -l #{ENV['PATH_TO_CREDS']} #{manifest_path}").
            and_return(nil)
          expect(UnitTestsUtils::Bosh).to receive(:`).once.
            with("bosh -d #{deployment_name} task > /dev/null 2>&1")

          UnitTestsUtils::Bosh.deploy(deployment_name, manifest_path)
        end
      end

      context "when additional vars are given" do
        it "runs a bosh deployment" do
          expect(UnitTestsUtils::Bosh).to receive(:`).once.
            with("bosh --non-interactive -d #{deployment_name} deploy -l #{ENV['PATH_TO_IAAS_CONFIG']} -l #{ENV['PATH_TO_CREDS']} #{additional_vars_string} #{manifest_path}").
            and_return(nil)
          expect(UnitTestsUtils::Bosh).to receive(:`).once.
            with("bosh -d #{deployment_name} task > /dev/null 2>&1")

          UnitTestsUtils::Bosh.deploy(deployment_name, manifest_path, additional_vars)
        end
      end
    end

    context "when the PATH_TO_CREDS env var is not set" do
      before :each do
        expect(ENV).to receive(:[]).with('PATH_TO_CREDS').
          and_return(nil)
      end

      context "when NO additional vars are given" do
        it "runs a bosh deployment" do
          expect(UnitTestsUtils::Bosh).to receive(:`).once.
            with("bosh --non-interactive -d #{deployment_name} deploy -l #{ENV['PATH_TO_IAAS_CONFIG']} #{manifest_path}").
            and_return(nil)
          expect(UnitTestsUtils::Bosh).to receive(:`).once.
            with("bosh -d #{deployment_name} task > /dev/null 2>&1")

          UnitTestsUtils::Bosh.deploy(deployment_name, manifest_path)
        end
      end

      context "when additional vars are given" do
        it "runs a bosh deployment" do
          expect(UnitTestsUtils::Bosh).to receive(:`).once.
            with("bosh --non-interactive -d #{deployment_name} deploy -l #{ENV['PATH_TO_IAAS_CONFIG']} #{additional_vars_string} #{manifest_path}").
            and_return(nil)
          expect(UnitTestsUtils::Bosh).to receive(:`).once.
            with("bosh -d #{deployment_name} task > /dev/null 2>&1")

          UnitTestsUtils::Bosh.deploy(deployment_name, manifest_path, additional_vars)
        end
      end
    end
  end

  describe ".delete_deployment" do
    it "runs a bosh delete-deployment" do
      expect(UnitTestsUtils::Bosh).to receive(:`).once.
        with("bosh --non-interactive -d #{deployment_name} delete-deployment --force")
      expect(UnitTestsUtils::Bosh).to receive(:`).once.
        with("bosh -d #{deployment_name} task > /dev/null 2>&1")

      UnitTestsUtils::Bosh.delete_deployment(deployment_name)
    end
  end

  describe ".start_instance" do
    context "when the index is given" do
      let(:index) { 1 }
      it "runs a bosh start on the given instance and index" do
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh --non-interactive -d #{deployment_name} start #{instance_name}/#{index} --force")
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh -d #{deployment_name} task > /dev/null 2>&1")

        UnitTestsUtils::Bosh.start_instance(deployment_name, instance_name, index)
      end
    end

    context "when the index is not given" do
      it "runs a bosh start on the given instance with index 0" do
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh --non-interactive -d #{deployment_name} start #{instance_name}/0 --force")
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh -d #{deployment_name} task > /dev/null 2>&1")

        UnitTestsUtils::Bosh.start_instance(deployment_name, instance_name)
      end
    end
  end

  describe ".stop_instance" do
    context "when the index is given" do
      let(:index) { 1 }
      it "runs a bosh stop on the given instance and index" do
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh --non-interactive -d #{deployment_name} stop #{instance_name}/#{index} --hard --force")
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh -d #{deployment_name} task > /dev/null 2>&1")

        UnitTestsUtils::Bosh.stop_instance(deployment_name, instance_name, index)
      end
    end

    context "when the index is not given" do
      it "runs a bosh stop on the given instance with index 0" do
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh --non-interactive -d #{deployment_name} stop #{instance_name}/0 --hard --force")
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh -d #{deployment_name} task > /dev/null 2>&1")

        UnitTestsUtils::Bosh.stop_instance(deployment_name, instance_name)
      end
    end
  end

  describe ".create_and_upload_dev_release" do
    let(:base_dir) { './' }
    let(:release_path) { File.join(base_dir, 'dev_releases', release_name, "#{release_name}-#{release_version}.yml") }
    let(:metadata) { { unit_test_name: release_name, unit_test_release_name: release_name, unit_test_release_version: release_version, unit_test_release_commit_hash: '4a207a6+' } }

    it "runs a bosh create-release and upload-release" do
      expect(UnitTestsUtils::Bosh).to receive(:`).once.
        with("bosh --json create-release --dir #{base_dir} --name #{release_name} --force").
        and_return(bosh_release_output(release_name, release_version))
      expect(UnitTestsUtils::Bosh).to receive(:`).once.
        with("bosh upload-release --dir #{base_dir} #{release_path}")

      expect(UnitTestsUtils::Bosh.create_and_upload_dev_release(base_dir, release_name)).to eq metadata
    end
  end

  def bosh_release_output(release_name, release_version)
    raw_json = Fixtures.file_content('bosh-create-release-output.json')
    json = JSON.parse(raw_json)

    json['Tables'][0]['Rows'][0]['name'] = release_name
    json['Tables'][0]['Rows'][0]['version'] = release_version

    json.to_json
  end

  describe ".delete_release" do
    it "runs a bosh delete-release" do
      expect(UnitTestsUtils::Bosh).to receive(:`).once.
        with("bosh --non-interactive delete-release #{release_name}")

      UnitTestsUtils::Bosh.delete_release(release_name)
    end
  end

  describe ".ssh" do
    let(:command) { "ls" }

    context "when an instance name is given" do
      context "when an index is given" do
        let(:index) { "1" }

        it "runs bosh ssh" do
          expect(UnitTestsUtils::Bosh).to receive(:`).once.
            with("bosh -d #{deployment_name} ssh #{instance_name}/#{index} -c '#{command}'")

          UnitTestsUtils::Bosh.ssh(deployment_name, command, instance_name, index)
        end
      end

      context "when the index is not given" do
        it "runs bosh ssh" do
          expect(UnitTestsUtils::Bosh).to receive(:`).once.
            with("bosh -d #{deployment_name} ssh #{instance_name}/0 -c '#{command}'")

          UnitTestsUtils::Bosh.ssh(deployment_name, command, instance_name)
        end
      end
    end

    context "when no instance is given" do
      it "runs bosh ssh" do
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh -d #{deployment_name} ssh -c '#{command}'")

        UnitTestsUtils::Bosh.ssh(deployment_name, command)
      end
    end
  end

  describe ".instance_status" do
    context "when the index is not given" do
      it "runs a bosh instance" do
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh --non-interactive -d #{deployment_name} instances --details --json").
          and_return(Fixtures.file_content('bosh-instances-details-output.json'))

        result = UnitTestsUtils::Bosh.instance_status(deployment_name, instance_name)
        expect(result.length).to eq(3)
      end
    end

    context "when the index is given" do
      it "runs a bosh instance" do
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh --non-interactive -d #{deployment_name} instances --details --json").
          and_return(Fixtures.file_content('bosh-instances-details-output.json'))

        result = UnitTestsUtils::Bosh.instance_status(deployment_name, instance_name, "0")
        expect(result.length).to eq(1)
        expect(result.first["index"]).to eq("0")
      end
    end

    context "when bosh is unavailable" do
      it "raises an exception" do
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh --non-interactive -d #{deployment_name} instances --details --json").
          and_return(Fixtures.file_content('bosh-instances-ps-error.json'))

        expect do
          UnitTestsUtils::Bosh.instance_status(deployment_name, instance_name)
        end.to raise_error(Exception, "Could not find 'Tables'. Maybe this is a request timeout.")
      end
    end

    context "when bosh gives an invalid json as response" do
      it "raises a json exception" do
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh --non-interactive -d #{deployment_name} instances --details --json").
          and_return(Fixtures.file_content('bosh-invalid-json-output.json'))

        expect do
          UnitTestsUtils::Bosh.instance_status(deployment_name, instance_name)
        end.to raise_error(JSON::ParserError)
      end
    end
  end
end
