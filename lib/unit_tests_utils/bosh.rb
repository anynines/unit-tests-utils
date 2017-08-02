module UnitTestsUtils::Bosh
  def self.deploy(deployment_name, manifest_path)
    if ENV['PATH_TO_CREDS']
      `bosh --non-interactive -d #{deployment_name} deploy -l #{ENV['PATH_TO_CREDS']} -l #{ENV['PATH_TO_IAAS_CONFIG']} #{manifest_path}`
    else
      `bosh --non-interactive -d #{deployment_name} deploy -l #{ENV['PATH_TO_IAAS_CONFIG']} #{manifest_path}`
    end
    wait_for_task_to_finish(deployment_name)
  end

  def self.delete_deployment(deployment_name)
    `bosh --non-interactive -d #{deployment_name} delete-deployment --force`
    wait_for_task_to_finish(deployment_name)
  end

  def self.start_instance(deployment_name, instance_name, index="0")
    `bosh --non-interactive -d #{deployment_name} start #{instance_name}/#{index} --force`
    wait_for_task_to_finish(deployment_name)
  end

  def self.stop_instance(deployment_name, instance_name, index="0")
    `bosh --non-interactive -d #{deployment_name} stop #{instance_name}/#{index} --hard --force`
    wait_for_task_to_finish(deployment_name)
  end

  def self.ssh(deployment_name, command, instance_name="", index="")
    if instance_name
      `bosh -d #{deployment_name} ssh #{instance_name}/#{index} -c #{command}`
    else
      `bosh -d #{deployment_name} ssh -c #{command}`
    end
  end


  private

  def self.wait_for_task_to_finish(deployment_name)
    `bosh -d #{deployment_name} task > /dev/null 2>&1`
  end
end
