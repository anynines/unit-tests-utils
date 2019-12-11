require 'spec_helper'

describe UnitTestsUtils::Manifest do
  let(:manifest_path) { Fixtures.file_path("manifest-with-static-name.yml") }
  let(:manifest_additional_vars) { { unit_test_name: 'service-ha', key1: 'value1', key2: 'value2' } }
  let(:manifest_yaml) {
    interpolated_manifest = UnitTestsUtils::Bosh.interpolate(manifest_path, manifest_additional_vars)
    YAML.load(interpolated_manifest)
  }
  let(:manifest_instance_names) { ['database', 'backup'] }
  let(:manifest_hostnames) { {
    "database/0" => "service-ha-database-0.node.datacenter.foo",
    "database/1" => "service-ha-database-1.node.datacenter.foo",
    "database/2" => "service-ha-database-2.node.datacenter.foo",
    "backup/0" => "service-ha-backup-0.node.datacenter.foo"
  } }
  let(:manifest) { UnitTestsUtils::Manifest.new(manifest_path) }
  let(:path_to_creds) { Fixtures.file_path 'creds.yml' }
  let(:path_to_iaas_config) { Fixtures.file_path 'iaas_config.yml' }

  before :each do
    stubbed_env = ENV.clone
    stubbed_env['PATH_TO_IAAS_CONFIG'] = path_to_iaas_config
    stubbed_env['PATH_TO_CREDS'] = path_to_creds
    stub_const('ENV', stubbed_env)
  end

  describe ".create" do
    context "when no manifest with the name exists" do
      it "creates a new instance and returns them" do
        manifest = UnitTestsUtils::Manifest.create(:TEST_CREATE_1, manifest_path, manifest_additional_vars)

        expect(manifest.path).to eq manifest_path
        expect(manifest.manifest).to eq manifest_yaml
        expect(manifest.additional_vars).to eq manifest_additional_vars
      end
    end

    context "when a manifest for the name already exist" do
      before(:example) do
        UnitTestsUtils::Manifest.create(:TEST_CREATE_2, manifest_path, manifest_additional_vars)
      end

      it "raises an error" do
        expect { UnitTestsUtils::Manifest.create(:TEST_CREATE_2, manifest_path, manifest_additional_vars) }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".fetch" do
    context "when no manifest with the name exists" do
      it "raises an error" do
        expect { UnitTestsUtils::Manifest.fetch(:TEST_GET_1) }.to raise_error(ArgumentError)
      end
    end

    context "when a manifest for the name already exist" do
      before(:example) do
        UnitTestsUtils::Manifest.create(:TEST_GET_2, manifest_path, manifest_additional_vars)
      end

      it "returns the manifest for that name" do
        manifest = UnitTestsUtils::Manifest.fetch(:TEST_GET_2)

        expect(manifest.path).to eq manifest_path
        expect(manifest.manifest).to eq manifest_yaml
        expect(manifest.additional_vars).to eq manifest_additional_vars
      end
    end
  end

  describe ".create_from_env" do
    context "when environment variables with such prefixes exists" do
      it "creates new instances for those names"
    end

    context "when no environment variables with such prefixes exists" do
      it "creates does nothing"
    end
  end

  describe ".new" do
    context "when just a manifest_path is given" do
      it "creates an object and sets the @path, loads the @manifest and sets empty @additional_vars" do
        manifest_without_additional_vars = UnitTestsUtils::Manifest.new(manifest_path)

        expect(manifest_without_additional_vars.path).to eq manifest_path
        expect(manifest_without_additional_vars.manifest).to eq manifest_yaml
        expect(manifest_without_additional_vars.additional_vars).to eq({})
      end
    end

    context "when a manifest_path and additional vars are given" do
      context "when additional vars contains symbols as keys" do
        it "creates an object and sets the @path, loads the @manifest and sets the @additional_vars" do
          manifest_with_additional_vars = UnitTestsUtils::Manifest.new(manifest_path, manifest_additional_vars)

          expect(manifest_with_additional_vars.path).to eq manifest_path
          expect(manifest_with_additional_vars.manifest).to eq manifest_yaml
          expect(manifest_with_additional_vars.additional_vars).to eq manifest_additional_vars
        end
      end

      context "when additional vars contains strings as keys" do
        let(:manifest_additional_vars_strings) { { 'unit_test_name' => 'service-ha', 'key1' => 'value1', 'key2' => 'value2' } }

        it "creates an object and sets the @path, loads the @manifest, converts the string keys from the additional vars to symbol keys and sets the @additional_vars" do
          manifest_with_additional_vars = UnitTestsUtils::Manifest.new(manifest_path, manifest_additional_vars_strings)

          expect(manifest_with_additional_vars.path).to eq manifest_path
          expect(manifest_with_additional_vars.manifest).to eq manifest_yaml
          expect(manifest_with_additional_vars.additional_vars).to eq manifest_additional_vars
        end
      end
    end
  end

  describe "#name" do
    context "when name is static" do
      it "returns the name found in the manifest" do
        expect(manifest.name).to eq manifest_yaml['name']
      end
    end

    context "when name is dynamic and set in the additional vars" do
      let(:manifest_path) { Fixtures.file_path("manifest-with-dynamic-name.yml") }
      let(:manifest) { UnitTestsUtils::Manifest.new(manifest_path, manifest_additional_vars) }

      it "returns the name from the additional vars" do
        expect(manifest.name).to eq manifest_additional_vars[:unit_test_name]
      end
    end

    context "when name is dynamic and NOT set in the additional vars" do
      let(:manifest_path) { Fixtures.file_path("manifest-with-dynamic-name.yml") }
      let(:manifest_yaml) {
        interpolated_manifest = UnitTestsUtils::Bosh.interpolate(manifest_path, manifest_additional_vars)
        YAML.load(interpolated_manifest)
      }
      let(:manifest) { UnitTestsUtils::Manifest.new(manifest_path) }

      it "returns the dynamic name" do
        expect(manifest.name).to eq manifest_yaml['name']
      end
    end
  end

  describe "#instance_names" do
    it "returns the name of all instances" do
      expect(manifest.instance_names).to eq manifest_instance_names
    end
  end

  describe "#instance_count" do
    it "returns to number of instances for a given instance_name" do
      expect(manifest.instance_count("database")). to eq 3
      expect(manifest.instance_count("backup")). to eq 1
    end
  end

  describe "#hostname" do
    context "when the instance_name is given" do
      context "when the index is given" do
        it "returns out the hostname of the service node with the specified index" do
          expect(manifest.hostname("database", "1")).to eq manifest_hostnames['database/1']
        end
      end

      context "when the index is not given" do
        it "returns out the hostname of the first service node" do
          expect(manifest.hostname("backup")).to eq manifest_hostnames['backup/0']
        end
      end
    end

    context "when neither an instance name nor an index are given" do
      it "returns out the hostname of the first service node" do
        expect(manifest.hostname).to eq manifest_hostnames['database/0']
      end
    end
  end

  describe "#hostnames" do
    it "returns all the hostnames of the manifest" do
      expect(manifest.hostnames). to eq manifest_hostnames
    end
  end

  describe "#properties" do
    context "when global properties are present only" do
      let(:manifest_properties) { { "consul" => { "dc" => "datacenter", "domain" => "foo" } } }

      it "returns a hash including the global properties" do
        expect(manifest.properties).to eq manifest_properties
      end
    end

    context "when local properties are present only" do
      let(:manifest_path) { Fixtures.file_path("manifest-with-local-properties-only.yml") }
      let(:manifest_properties) { { 'property0' => 0, 'property1' => 1 } }

      it "returns a hash including the local properties" do
        expect(manifest.properties).to eq manifest_properties
      end
    end

    context "when both local and global properties are present" do
      let(:manifest_path) { Fixtures.file_path("manifest-with-both-global-local-properties.yml") }
      let(:manifest_properties) { {"consul"=>{"dc"=>"datacenter", "domain"=>"foo"}, "property0"=>0, "property1"=>1} }

      it "returns a hash including both the global and local properties" do
        expect(manifest.properties).to eq manifest_properties
      end
    end
  end

  describe "#get_network" do
    let(:default_network) { "dynamic" }

    it "returns the default network when manifest unmodified" do
      expect(manifest.get_network(manifest.instance_names.first)).to eq default_network
    end
  end

  describe "#set_network" do
    let(:new_network) { "relocated" }

    it "sets the network properties in the manifest and we an get it" do
      manifest.set_network(manifest.instance_names.first, new_network)
      expect(manifest.get_network(manifest.instance_names.first)).to eq new_network
    end
  end
end
