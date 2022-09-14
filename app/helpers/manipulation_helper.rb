module ManipulationHelper
  def storage_system_where_clause(assoc, storage_systems = nil)
    if storage_systems.instance_of?(Array) && storage_systems.length >= 1
      storage_systems.map do |i|
        "#{events_table_name(assoc)}.physical_storage_id = #{i}"
      end.join(" OR ")
    end
  end
end