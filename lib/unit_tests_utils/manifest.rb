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

  def self.create_from_env(manifest_prefix, additional_vars = {})
    manifest_prefix_length= manifest_prefix.length

    ENV.each_key do |name|
      if name.start_with?(manifest_prefix)
        manifest_name = name[manifest_prefix_length..-1].to_sym

        self.create(manifest_name, ENV[name], additional_vars)
      end
    end
  end

  def initialize(manifest_path, additional_vars = {})
    @path = manifest_path
    interpolated_manifest = UnitTestsUtils::Bosh.interpolate(manifest_path, additional_vars)
    @manifest = YAML.load(interpolated_manifest)
    @additional_vars = Hash[additional_vars.map { |key, value| [key.to_sym, value] }]
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
    instance_group(instance_name)['instances']
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
          if properties
            hostnames["#{instance_name}/#{index}"] = "#{name}-#{instance_name}-#{index}.node.#{properties['consul']['dc']}.#{properties['consul']['domain']}"
          else
            hostnames["#{instance_name}/#{index}"] = "#{name}-#{instance_name}-#{index}.node.#{properties_for_instance_group(instance_name)['consul']['dc']}.#{properties_for_instance_group(instance_name)['consul']['domain']}"
          end
        end
      end

      hostnames
    end
  end

  def properties
    manifest['properties']
  end

  def properties_for_instance_group(instance_name)
    instance_group(instance_name)['properties']
  end

  # get_network returns the network of listed in the deployment manifest. This
  # is not necessarily what is in the manifest file as the property can be
  # altered with set_network. The network returned is the value of
  # properties.network for the instance group that is named identically to the
  # instance name.
  # Raises an exception if the properties.network is not found in the networks
  # section of the instance group.
  def get_network(instance_name)
    network = instance_group(instance_name)['properties']['network']
    if instance_group(instance_name)['networks'].any? { |n| n['name'] == network }
      return network
    end
    raise "properties.network was not found in networks"
  end

  # set_network changes the network in the internal representation of the
  # manifest. This function does not effect what is in the manifest file.
  def set_network(instance_name, new_network)
    old_network = get_network(instance_name)
    ig = instance_group(instance_name)
    ig['networks'].delete_if { |n| n['name'] == old_network }
    ig['properties']['network'] = new_network
    ig['networks'].push( { "name" => new_network }  )
  end

  private

  def instance_group(instance_name)
    manifest['instance_groups']
      .select { |instance_group| instance_group['name'] == instance_name }
      .first
  end
end
