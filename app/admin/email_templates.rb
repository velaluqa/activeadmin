ActiveAdmin.register EmailTemplate do
  config.filters = false

  permit_params(:name, :email_type, :template)
end
