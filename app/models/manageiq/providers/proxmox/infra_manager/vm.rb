class ManageIQ::Providers::Proxmox::InfraManager::Vm < ManageIQ::Providers::InfraManager::Vm
  include Operations
  include RemoteConsole
  include ManageIQ::Providers::Proxmox::InfraManager::Vm::Reconfigure
  include ManageIQ::Providers::Proxmox::InfraManager::Vm::Operations::Configuration
#  include Reconfigure

  supports :terminate
  supports :reboot_guest
  supports :reset
  supports :suspend
  supports :start
  supports :stop
  supports :shutdown_guest

  POWER_STATES = {
    'running'   => 'on',
    'stopped'   => 'off',
    'paused'    => 'paused',
    'suspended' => 'suspended'
  }.freeze

  def power_state
    self.class.calculate_power_state(raw_power_state)
  end


  def self.calculate_power_state(raw_power_state)
    POWER_STATES[raw_power_state] || super
  end

  def raw_start
    with_provider_connection do |connection|
      connection.post("nodes/#{location}/status/start")
    end
    self.update!(:raw_power_state => 'running')
  end

  def raw_stop
    with_provider_connection do |connection|
      connection.post("nodes/#{location}/status/stop")
    end
    self.update!(:raw_power_state => 'stopped')
  end

  def raw_suspend
    with_provider_connection do |connection|
      connection.post("nodes/#{location}/status/suspend")
    end
    self.update!(:raw_power_state => 'paused')
  end

  def raw_reboot_guest
    with_provider_connection do |connection|
      connection.post("nodes/#{location}/status/reboot")
    end
  end

  def raw_reset
    with_provider_connection do |connection|
      connection.post("nodes/#{location}/status/reset")
    end
  end

  def raw_shutdown_guest
    with_provider_connection do |connection|
      connection.post("nodes/#{location}/status/shutdown")
    end
    self.update!(:raw_power_state => 'stopped')
  end

  def remove_snapshot_queue(snap_id, userid = "system")
    task_opts = {
      :action => "removing snapshot for VM '#{name}'",
      :userid => userid
    }
    
    queue_opts = {
      :class_name  => self.class.name,
      :instance_id => id,
      :method_name => 'remove_snapshot_async',
      :priority    => MiqQueue::HIGH_PRIORITY,
      :role        => 'ems_operations',
      :zone        => my_zone,
      :args        => [snap_id]
    }
    
    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def params_for_create_snapshot
    {
      :fields => [
        {
          :component  => 'textarea',
          :name       => 'description',
          :id         => 'description',
          :label      => _('Description'),
          :isRequired => true,
          :validate   => [{:type => 'required'}],
        },
        {
          :component  => 'switch',
          :name       => 'memory',
          :id         => 'memory',
          :label      => _('Snapshot VM memory'),
          :onText     => _('Yes'),
          :offText    => _('No'),
          :isDisabled => current_state != 'on',
          :helperText => _('Snapshotting the memory is only available if the VM is powered on.'),
        },
      ],
    }
  end

end


