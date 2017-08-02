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
      instance_names = []

      manifest['instance_groups'].map do |instance_group|
        (0..instance_count(instance_group['name'])-1).each { |i| instance_names << "#{instance_group['name']}/#{i}" }
      end

      instance_names
    end
  end

  def instance_count(instance_name)
    manifest['instance_groups']
      .select { |instance_group| instance_group['name'] == instance_name }
      .first['instances']
  end

  def hostname(instance_name = nil)
    instance_name ||= self.instance_names.first

    hostnames[instance_name]
  end

  def hostnames
    @hostnames ||= begin
      hostnames = {}

      instance_names.each do |instance_name|
        value = instance_name.sub('/', '-')

        hostnames["#{instance_name}"] = "#{name}-#{value}.node.#{properties['consul']['dc']}.#{properties['consul']['domain']}"
      end

      hostnames
    end
  end

  def properties
    manifest['properties']
  end
end
