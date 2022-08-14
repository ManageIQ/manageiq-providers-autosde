class AutosdeSetup
  def self.service_catalog_components
    ### SETUP SERVICE CATALOG COMPONENTS ###
    # CATALOG
    catalog_name = "AutoSDE Catalog"
    catalog_id = ServiceTemplateCatalog.find_or_create_by(:name => catalog_name).id

    # DIALOG
    vol_dialog = YAML.load_file("plugins/manageiq-providers-autosde/content/miq/dialogs/volume.yaml")
    catalog_name = vol_dialog["label"]
    exist_dialog = Dialog.find_by(:label => catalog_name)
    vol_dialog_id = if exist_dialog
                      exist_dialog.id
                    else
                      DialogImportService.new.import(vol_dialog).id
                    end
    # ITEM
    vol_item_prop = { :name => "Volume", :prov_type => "autosde", :display => "true", :service_template_catalog_id => catalog_id,
                      :config_info => { :provision => { :fqname => "/Storage/AutoSde/ServiceVolumeRequestApproval/Default", :dialog_id => vol_dialog_id }}}
    ServiceTemplate.create_catalog_item(vol_item_prop, nil) unless ServiceTemplate.find_by(:name => vol_item_prop[:name]) != nil
  end
end