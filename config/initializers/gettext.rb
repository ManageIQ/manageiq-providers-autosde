Vmdb::Gettext::Domains.add_domain(
  'ManageIQ::Providers::Autosde',
  ManageIQ::Providers::Autosde::Engine.root.join('locale').to_s,
  :po
)
