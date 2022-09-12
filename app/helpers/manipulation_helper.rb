module ManipulationHelper
  def manipulate_storage_systems(assoc, storage_systems=nil)
    if storage_systems.instance_of? Array and storage_systems.length >=1
      rec_cond = ""
      storage_systems.each do |i|
        rec_cond = rec_cond + "#{events_table_name(assoc)}.physical_storage_id = #{i}"
        unless i.equal?storage_systems.last
          rec_cond = rec_cond + " or "
        end
      end
      return rec_cond
    end
  end
end
