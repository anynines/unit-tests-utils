require 'json'

module UnitTestsUtils::Bosh
  def self.deploy(deployment_name, manifest_path, additional_vars = [])
    vars = "-l #{ENV['PATH_TO_IAAS_CONFIG']}"
    vars << " -l #{ENV['PATH_TO_CREDS']}" if ENV['PATH_TO_CREDS']
    additional_vars.each { |key, value| vars << " --var #{key}=#{value}" }

    `bosh --non-interactive -d #{deployment_name} deploy #{vars} #{manifest_path}`
    wait_for_task_to_finish(deployment_name)
  end

  def self.delete_deployment(deployment_name)
    `bosh --non-interactive -d #{deployment_name} delete-deployment --force`
    wait_for_task_to_finish(deployment_name)
  end

  def self.start_instance(deployment_name, instance_name, index = '0')
    `bosh --non-interactive -d #{deployment_name} start #{instance_name}/#{index} --force`
    wait_for_task_to_finish(deployment_name)
  end

  def self.stop_instance(deployment_name, instance_name, index = '0')
    `bosh --non-interactive -d #{deployment_name} stop #{instance_name}/#{index} --hard --force`
    wait_for_task_to_finish(deployment_name)
  end

  def self.create_and_upload_dev_release(base_dir, release_name, version_prefix = '')
    version = dev_release_version(version_prefix)
    raw_json = `bosh --json create-release --dir #{base_dir} --name #{release_name} --version #{version} --force`
    metadata = parse_json_from_create_release(raw_json)

    release_name = "#{metadata[:unit_test_release_name]}-#{metadata[:unit_test_release_version]}.yml"
    release_path = File.join(base_dir, 'dev_releases', metadata[:unit_test_release_name], release_name)
    `bosh upload-release --dir #{base_dir} #{release_path}`

    metadata
  end

  def self.instance_status(deployment_name, instance_name, index = nil)
    json = JSON.parse(`bosh --non-interactive -d #{deployment_name} instances --details --json`)

    raise Exception.new("Could not find 'Tables'. Maybe this is a request timeout.") if json['Tables'].nil?

    rows = json['Tables'].first.select { |table| table == 'Rows' }
    rows['Rows'].select do |vm|
      vm['instance'].split('/')[0] == instance_name and
      (index.nil? or vm['index'] == index)
    end
  end

  def self.delete_release(release_name, release_version = nil)
    release_name << "/#{release_version}" unless release_version.nil?

    `bosh --non-interactive delete-release #{release_name}`
  end

  def self.ssh(deployment_name, command, instance_name = nil, index = '0')
    if instance_name
      `bosh -d #{deployment_name} ssh #{instance_name}/#{index} -c '#{command}'`
    else
      `bosh -d #{deployment_name} ssh -c '#{command}'`
    end
  end


  private

  def self.wait_for_task_to_finish(deployment_name)
    `bosh -d #{deployment_name} task > /dev/null 2>&1`
  end

  def self.dev_release_version(version_prefix)
    version = "dev."
    version << "#{version_prefix}." unless version_prefix.empty?
    version << Time.now.to_i.to_s

    version
  end

  def self.parse_json_from_create_release(raw_json)
    json = JSON.parse(raw_json)
    metadata = json['Tables'].select { |table| table['Content'].empty? }.first['Rows'].first
    normalized_version = metadata['version'].gsub('.', '-')

    {
      unit_test_name: "#{metadata['name']}-#{normalized_version}",
      unit_test_release_name: metadata['name'],
      unit_test_release_version: metadata['version'],
      unit_test_release_commit_hash: metadata['commit_hash']
    }
  end
end
