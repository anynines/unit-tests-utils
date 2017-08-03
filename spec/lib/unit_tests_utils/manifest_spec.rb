require 'spec_helper'
require_relative '../../../lib/unit_tests_utils/'

describe UnitTestsUtils::Manifest do
  let(:manifest_path) { (File.dirname(__FILE__) + "/../../fixtures/manifest.yml") }
  let(:manifest_yaml) { YAML.load_file(manifest_path) }
  let(:manifest) { UnitTestsUtils::Manifest.new(manifest_path) }

  describe ".new" do
    it "creates an object and sets a value for @path and @manifest" do
      manifest = UnitTestsUtils::Manifest.new(manifest_path)

      expect(manifest.path).to eq manifest_path
      expect(manifest.manifest).to eq manifest_yaml
    end
  end

  describe "#name" do
    it "returns the name found in the manifest" do
      expect(manifest.name).to eq manifest_yaml['name']
    end
  end

  describe "#instance_names" do
    it "returns the name of all instances" do
      expect(manifest.instance_names).to eq ["database", "backup"]
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
      let(:instance_name) { "database" }

      context "when the index is given" do
        it "returns out the hostname of the service node" do
          expect(manifest.hostname(instance_name, "1")).
            to eq "service-ha-database-1.node.datacenter.foo"
        end
      end

      context "when the index is not given" do
        it "returns out the hostname of the first service node" do
          expect(manifest.hostname(instance_name)).
            to eq "service-ha-database-0.node.datacenter.foo"
        end
      end
    end

    context "when the instance_name is not given" do
      it "returns out the hostname of the first service node" do
        expect(manifest.hostname).
          to eq "service-ha-database-0.node.datacenter.foo"
      end
    end
  end

  describe "#hostnames" do
    it "returns all the hostnames of the manifest" do
      expect(manifest.hostnames).
        to eq({
        "database/0" => "service-ha-database-0.node.datacenter.foo",
        "database/1" => "service-ha-database-1.node.datacenter.foo",
        "database/2" => "service-ha-database-2.node.datacenter.foo",
        "backup/0" => "service-ha-backup-0.node.datacenter.foo"
      })
    end
  end

  describe "#properties" do
    it "returns a hash of the properties" do
      expect(manifest.properties).
        to eq(
          {
             "consul" => {
               "dc" => "datacenter",
               "domain" => "foo"
            }
          }
      )
    end
  end
end
