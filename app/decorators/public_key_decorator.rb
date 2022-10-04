class PublicKeyDecorator < ApplicationDecorator
  delegate_all

  include Draper::LazyHelpers

  def public_key
    link_to('Download', download_admin_public_key_path(model))
  end

  def status
    if model.active?
      status_tag('Active', class: 'ok')
    else
      status_tag('Deactivated', label: 'Deactivated at ' + pretty_format(model.deactivated_at))
    end
  end
end