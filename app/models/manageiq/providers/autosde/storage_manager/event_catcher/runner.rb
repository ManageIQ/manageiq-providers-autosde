class ManageIQ::Providers::Autosde::StorageManager::EventCatcher::Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
  def event_monitor_handle
    @event_monitor_handle ||= self.class.module_parent::Stream.new(@ems)
  end

  def reset_event_monitor_handle
    @autosde_client = nil
  end

  def stop_event_monitor
    event_monitor_handle.stop
  end

  def monitor_events
    event_monitor_handle.start

    event_monitor_running

    event_monitor_handle.poll_events do |event|
      @queue.enq(event)
    end
  ensure
    stop_event_monitor
  end

  def queue_event(event)
    _log.info("#{log_prefix} Caught event AutoSDE [#{event.event_id}]")
    add_notification_type(event)
    event_hash = event_to_hash(event, @cfg[:ems_id])
    EmsEvent.add_queue('add', @cfg[:ems_id], event_hash)
  end

  def add_notification_type(event)
    NotificationType.create_with(
      :name       => event.event_type,
      :level      => "warning",
      :audience   => "global",
      :expires_in => 7.days,
      :message    => "%{event_type} in event %{uuid}, error code: %{error_code}. %{description}"
    ).find_or_create_by(:name => event.event_type)
  end

  private

  def parse_event_type(event)
    event.fixed == 'yes' ? "#{event.event_type}_fixed" : event.event_type
  end

  def event_to_hash(event, ems_id)
    {
      :event_type               => parse_event_type(event),
      :source                   => "AUTOSDE",
      :ems_ref                  => event.event_id,
      :physical_storage_ems_ref => event.storage_system,
      :timestamp                => event.last_timestamp,
      :full_data                => event.to_hash,
      :ems_id                   => ems_id,
      :message                  => event.description
    }
  end
end
