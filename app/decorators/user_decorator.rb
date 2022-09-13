class UserDecorator < ApplicationDecorator
  delegate_all

  include Draper::LazyHelpers

  def name
    link_to(model.name, admin_user_path(model))
  end

  def key_pair
    if model.public_key.nil? || model.private_key.nil?
      status_tag('Missing', class: 'error')
    else
      status_tag('Present', class: 'ok')
    end
  end

  def currently_signed_in
    if model.current_sign_in_at.nil?
      'No'
    else
      "Yes, since #{pretty_format(model.current_sign_in_at)} from #{model.current_sign_in_ip}"
    end
  end

  def last_sign_in
    if model.last_sign_in_at.nil?
      'Never'
    else
      "#{pretty_format(model.last_sign_in_at)} from #{model.last_sign_in_ip}"
    end
  end

  def public_key
    if model.public_key.nil?
      status_tag('Missing', class: 'error')
    else
      link_to('Download Public Key', download_public_key_admin_user_path(model))
    end
  end

  def past_public_keys
    link_to(model.public_keys.count, admin_public_keys_path(:'q[user_id_eq]' => model.id))
  end

  def locked
    if model.access_locked?
      status_tag("Locked at #{pretty_format(user.locked_at)}", class: 'error')
    else
      status_tag('Unlocked', class: 'ok')
    end
  end

  def impersonate
    link_to('Impersonate', impersonate_admin_user_path(model)) if can?(:impersonate, model)
  end

  def confirmed
    if model.confirmed?
      status_tag("Confirmed at #{pretty_format(model.confirmed_at)}", class: 'ok')
    else
      status_tag('Unconfirmed', class: 'error')
    end
  end

  def roles
    link_to("#{model.user_roles.count} Roles", admin_user_user_roles_path(user_id: model.id)) if can?(:read, Role) && can?(:read, UserRole)
  end
end