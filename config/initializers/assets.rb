# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'fonts')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile +=
  %w[
    application.css
    dashboard/main.js
    vendor/dicomParser.js
    uploader/main.js
    email_templates/form.js
    patients/visit_templates.js
    forms_bootstrap_and_overrides.css
    image_hierarchy.js
    tqc_validation.js
    mqc_validation.js
    role_form.js
    notification_profiles/filters_json_editor.js
    image_series_rearrange.js
  ]
