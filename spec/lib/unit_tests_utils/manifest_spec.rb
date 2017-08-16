require 'spec_helper'
require_relative '../../../lib/unit_tests_utils/'

describe UnitTestsUtils::Manifest do
  let(:manifest_path) { Fixtures.file_path("manifest-with-static-name.yml") }
  let(:manifest_additional_vars) { { unit_test_name: 'service-ha', key1: 'value1', key2: 'value2' } }
  let(:manifest_yaml) { YAML.load_file(manifest_path) }
  let(:manifest_instance_names) { ['database', 'backup'] }
  let(:manifest_hostnames) { {
    "database/0" => "service-ha-database-0.node.datacenter.foo",
    "database/1" => "service-ha-database-1.node.datacenter.foo",
    "database/2" => "service-ha-database-2.node.datacenter.foo",
    "backup/0" => "service-ha-backup-0.node.datacenter.foo"
  } }
  let(:manifest) { UnitTestsUtils::Manifest.new(manifest_path) }

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
      it "creates an object and sets the @path, loads the @manifest and sets the @additional_vars" do
        manifest_with_additional_vars = UnitTestsUtils::Manifest.new(manifest_path, manifest_additional_vars)

        expect(manifest_with_additional_vars.path).to eq manifest_path
        expect(manifest_with_additional_vars.manifest).to eq manifest_yaml
        expect(manifest_with_additional_vars.additional_vars).to eq manifest_additional_vars
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
      let(:manifest_yaml) { YAML.load_file(manifest_path) }
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
    let(:manifest_properties) { { "consul" => { "dc" => "datacenter", "domain" => "foo" } } }

    it "returns a hash of the properties" do
      expect(manifest.properties).to eq manifest_properties
    end
  end
end
