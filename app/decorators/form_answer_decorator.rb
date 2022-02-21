class FormAnswerDecorator < ApplicationDecorator
  delegate_all

  include Draper::LazyHelpers

  def status
    if submitted_at
      status_tag("submitted", class: "ok")
    else
      status_tag("draft")
    end
  end

  def signature_status
    if !answers_signature
      status_tag("none")
    elsif valid_signature?
      status_tag("valid", class: "ok")
    else
      status_tag("invalid", class: "warning")
    end
  end

  def user_public_key
    user = public_key.user
    link_to user.name, admin_public_key_path(public_key)
  end
end
