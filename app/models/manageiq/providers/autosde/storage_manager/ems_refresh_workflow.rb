class ManageIQ::Providers::Autosde::StorageManager::EmsRefreshWorkflow < ManageIQ::Providers::EmsRefreshWorkflow

  def run_native_op
    queue_signal(:poll_native_task)
  end
  alias start run_native_op

  def poll_native_task
    native_object = autosde_client.JobApi.jobs_pk_get(options[:native_task_id])
    case native_object.status
    when "FAILURE"
      signal(:abort, "Task failed")
    when "SUCCESS"
      options[:native_object_id] = native_object.object_id
      save!
      queue_signal(:refresh)
    else
      queue_signal(:poll_native_task, :deliver_on => Time.now.utc + options[:interval])
    end
  rescue => err
    _log.log_backtrace(err)
    signal(:abort, err.message, "error")
  end

  def refresh
    case options[:target_option]
    when "new"
      target = InventoryRefresh::Target.new(
        :manager     => ext_management_system,
        :association => options[:target_class],
        :manager_ref => {:ems_ref => options[:native_object_id]}
      )
    when "ems"
      target = ext_management_system
    when "existing"
      target = target_entity
    else
      signal(:abort, "error, no valid option")
    end
    task_ids = EmsRefresh.queue_refresh_task(target)
    if task_ids.blank?
      process_error("Failed to queue refresh", "error")
      queue_signal(:error)
    else
      context[:refresh_task_ids] = task_ids
      update!(:context => context)

      queue_signal(:poll_refresh)
    end
  end

  def autosde_client
    @autosde_client ||= ext_management_system.autosde_client
  end

  def ext_management_system
    @ext_management_system ||= ExtManagementSystem.find(options[:ems_id])
  end
end
