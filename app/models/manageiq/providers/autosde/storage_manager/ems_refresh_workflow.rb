class ManageIQ::Providers::Autosde::StorageManager::EmsRefreshWorkflow < ManageIQ::Providers::EmsRefreshWorkflow

  def run_native_op
    queue_signal(:poll_native_task)
  end
  alias start run_native_op

  def poll_native_task
    native_object = autosde_client.JobApi.jobs_pk_get(options[:native_task_id])
    case native_object.status
    when "FAILURE"
      raise "#{options[:target_class]} task failed: #{JSON.parse(native_object.result)["exc_message"][0]}"
    when "SUCCESS"
      options[:native_objects_ids] = native_object.objects_ids
      save!
      if options[:target_option] == 'new' && options[:target_class] == :physical_storages
        options[:target_option] = "ems"
        save!
        queue_signal(:poll_refresh_task, :deliver_on => Time.now.utc + options[:interval])
      else
        queue_signal(:refresh)
      end
    else
      queue_signal(:poll_native_task, :deliver_on => Time.now.utc + options[:interval])
    end
  rescue => err
    _log.log_backtrace(err)
    signal(:abort, err.message, "error")
  end

  def poll_refresh_task
    opts = {
      :query_params => {
        :object_id => options[:native_objects_ids][0]
      }
    }
    tasks = autosde_client.JobApi.jobs_get(opts)
    raise _('No refresh task found') if tasks.count < 1

    task = tasks.detect { |t| t.task_name.match?("update_system") }
    raise _('No refresh task found') if task.nil?

    case task.status
    when "FAILURE"
      signal(:abort, "Refresh failed")
    when "SUCCESS"
      queue_signal(:refresh)
    else
      queue_signal(:poll_refresh_task, :deliver_on => Time.now.utc + options[:interval])
    end
  rescue => err
    _log.log_backtrace(err)
    signal(:abort, err.message, opts)
  end

  def refresh
    case options[:target_option]
    when "new"
      targets = options[:native_objects_ids].to_a.map do |ems_ref|
        InventoryRefresh::Target.new(
          :manager     => ext_management_system,
          :association => options[:target_class],
          :manager_ref => {:ems_ref => ems_ref}
      )
      end
    when "ems"
      targets = ext_management_system
    when "existing"
      targets = target_entity
    else
      signal(:abort, "error, no valid option")
    end
    task_ids = EmsRefresh.queue_refresh_task(targets)
    if task_ids.blank?
      process_error("Failed to queue refresh", "error")
      queue_signal(:error)
    else
      context[:refresh_task_ids] = task_ids
      update!(:context => context)

      queue_signal(:poll_refresh)
    end
  end

  def load_transitions
    self.state ||= 'initialize'

    {
      :initializing      => {'initialize'       => 'waiting_to_start'},
      :start             => {'waiting_to_start' => 'running'},
      :poll_native_task  => {'running'          => 'running'},
      :poll_refresh_task => {'running'          => 'running'},
      :refresh           => {'running'          => 'refreshing'},
      :poll_refresh      => {'refreshing'       => 'refreshing'},
      :post_refresh      => {'refreshing'       => 'post_refreshing'},
      :finish            => {'*'                => 'finished'},
      :abort_job         => {'*'                => 'aborting'},
      :cancel            => {'*'                => 'canceling'},
      :error             => {'*'                => '*'}
    }
  end

  def autosde_client
    @autosde_client ||= ext_management_system.autosde_client
  end

  def ext_management_system
    @ext_management_system ||= ExtManagementSystem.find(options[:ems_id])
  end
end
