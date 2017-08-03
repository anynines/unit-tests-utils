require 'spec_helper'
require_relative '../../../lib/unit_tests_utils'

describe "UnitTestsUtils::Bosh" do
  let(:deployment_name) { "database-ha" }
  let(:manifest_path)   { "./database-ha.yml" }
  let(:instance_name)   { "database" }
  let(:release_name)    { "release_name" }

  describe ".deploy" do
    let(:path_to_creds) { './config.yml' }
    let(:path_to_iaas_config) { './iaas_config.yml' }

    before :each do
      expect(ENV).to receive(:[]).with('PATH_TO_IAAS_CONFIG').at_least(:once).
        and_return(path_to_iaas_config)
    end

    context "when the PATH_TO_CREDS env var is set" do
      before :each do
        expect(ENV).to receive(:[]).with('PATH_TO_CREDS').at_least(:once).
          and_return(path_to_creds)
      end

      it "runs a bosh deployment" do
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh --non-interactive -d #{deployment_name} deploy -l #{ENV['PATH_TO_CREDS']} -l #{ENV['PATH_TO_IAAS_CONFIG']} #{manifest_path}").
          and_return(nil)
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh -d #{deployment_name} task > /dev/null 2>&1")

        UnitTestsUtils::Bosh.deploy(deployment_name, manifest_path)
      end
    end

    context "when the PATH_TO_CREDS env var is not set" do
      before :each do
        expect(ENV).to receive(:[]).with('PATH_TO_CREDS').
          and_return(nil)
      end

      it "runs a bosh deployment" do
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh --non-interactive -d #{deployment_name} deploy -l #{ENV['PATH_TO_IAAS_CONFIG']} #{manifest_path}").
          and_return(nil)
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh -d #{deployment_name} task > /dev/null 2>&1")

        UnitTestsUtils::Bosh.deploy(deployment_name, manifest_path)
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
    let(:release_path) { base_dir + release_name }
    let(:releases) { [release_path] }

    before :each do
      expect(Dir).to receive(:[]).once.and_return(releases)
      expect(releases).to receive(:sort_by).once.and_return(releases)
    end

    it "runs a bosh create-release and upload-release" do
      expect(UnitTestsUtils::Bosh).to receive(:`).once.
        with("bosh create-release --dir #{base_dir} --name #{release_name} --force")
      expect(UnitTestsUtils::Bosh).to receive(:`).once.
        with("bosh upload-release --dir #{base_dir} #{release_path}")

      UnitTestsUtils::Bosh.create_and_upload_dev_release(base_dir, release_name)
    end
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

    context "when an instance is given" do
      context "when an index is given" do
        let(:index) { "1" }

        it "runs bosh ssh" do
          expect(UnitTestsUtils::Bosh).to receive(:`).once.
            with("bosh -d #{deployment_name} ssh #{instance_name}/#{index} -c #{command}")

          UnitTestsUtils::Bosh.ssh(deployment_name, command, instance_name, index)
        end
      end

      context "when the index is not given" do
        it "runs bosh ssh" do
          expect(UnitTestsUtils::Bosh).to receive(:`).once.
            with("bosh -d #{deployment_name} ssh #{instance_name}/0 -c #{command}")

          UnitTestsUtils::Bosh.ssh(deployment_name, command, instance_name)
        end
      end
    end

    context "when no instance is given" do
      it "runs bosh ssh" do
        expect(UnitTestsUtils::Bosh).to receive(:`).once.
          with("bosh -d #{deployment_name} ssh -c #{command}")

        UnitTestsUtils::Bosh.ssh(deployment_name, command)
      end
    end
  end
end
