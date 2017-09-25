require 'yaml'

class UnitTestsUtils::Manifest
  @@instances = {}

  attr_reader :path, :manifest, :additional_vars

  def self.create(name, manifest_path, additional_vars = {}, ignore_existing = false)
    raise ArgumentError, "Manifest for name #{name} already exists" if !ignore_existing && @@instances.has_key?(name)

    @@instances[name] = self.new(manifest_path, additional_vars)
  end

  def self.fetch(name)
    raise ArgumentError, "Manifest for name #{name} does not exist" unless @@instances.has_key?(name)

    @@instances[name]
  end

  def initialize(manifest_path, additional_vars = {})
    @path = manifest_path
    @manifest = YAML.load_file(manifest_path)
    @additional_vars = additional_vars
  end

  def name
    @name ||= begin
      additional_vars_key = manifest['name'][/^\(\((.*)\)\)$/, 1]
      additional_vars_key = additional_vars_key.to_sym if additional_vars_key

      if additional_vars_key && additional_vars.has_key?(additional_vars_key)
        additional_vars[additional_vars_key]
      else
        manifest['name']
      end
    end
  end

  def instance_names
    @instance_names ||= manifest['instance_groups'].map { |instance_group| instance_group['name'] }
  end

  def instance_count(instance_name)
    manifest['instance_groups']
      .select { |instance_group| instance_group['name'] == instance_name }
      .first['instances']
  end

  def hostname(instance_name = nil, index = '0')
    instance_name = instance_names.first unless instance_name
    key = "#{instance_name}/#{index}"

    hostnames[key]
  end

  def hostnames
    @hostnames ||= begin
      hostnames = {}

      instance_names.each do |instance_name|
        instance_count(instance_name).times do |index|
          hostnames["#{instance_name}/#{index}"] = "#{name}-#{instance_name}-#{index}.node.#{properties['consul']['dc']}.#{properties['consul']['domain']}"
        end
      end

      hostnames
    end
  end

  def properties
    manifest['properties']
  end
end
