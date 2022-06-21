class ManageIQ::Providers::Autosde::StorageManager::EventCatcher::Stream
  attr_reader :ems, :stop_polling, :poll_sleep

  def initialize(ems, options = {})
    @ems = ems
    @autosde_client ||= @ems.autosde_client.EventApi
    @stop_polling = false
    @poll_sleep = options[:poll_sleep] || 20.seconds
  end

  def start
    @stop_polling = false
  end

  def stop
    @stop_polling = true
  end

  def poll_events(&block)
    loop do
      events = @autosde_client.events_get

      break if stop_polling

      events.each(&block)
      sleep(poll_sleep)
    end
  end
end
