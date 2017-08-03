require 'yaml'

class UnitTestsUtils::Manifest
  attr_reader :path, :manifest

  def initialize(manifest_path)
    @path = manifest_path
    @manifest = YAML.load_file(manifest_path)
  end

  def name
    @name ||= manifest['name']
  end

  def instance_names
    @instance_names ||= begin
      manifest['instance_groups'].map do |instance_group|
        instance_group['name']
      end
    end
  end

  def instance_count(instance_name)
    manifest['instance_groups']
      .select { |instance_group| instance_group['name'] == instance_name }
      .first['instances']
  end

  def hostname(instance_name=nil, index="0")
    instance_name = instance_names.first if instance_names.nil?
    key = "#{instance_name}/#{index}"

    hostnames[key]
  end

  def hostnames
    @hostnames ||= begin
      hostnames = {}

      instance_names.each do |instance_name|
        instance_count(instance_name).times do |index|
          hostnames["#{instance_name}/#{index}"]  = "#{name}-#{instance_name}-#{index}.node.#{properties['consul']['dc']}.#{properties['consul']['domain']}"
        end
      end

      hostnames
    end
  end

  def properties
    manifest['properties']
  end
end
