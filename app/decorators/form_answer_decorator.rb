class FormAnswerDecorator < ApplicationDecorator
  delegate_all

  include Draper::LazyHelpers

  def invalid?
    @invalid ||= !object.valid?
  end

  def errors
    object.errors.to_a.join("<br>").html_safe
  end

  def resources
    count = form_answer_resources.length
    if count > 1
      "#{count} #{form_answer_resources.first.resource_type.pluralize}"
    elsif count == 1
      form_answer_resources.first.resource
    else
      nil
    end
  end

  def status
    if !object.valid?
      status_tag("invalid", class: "error")
    elsif signed?
      link_to status_tag("signed", class: "ok"), admin_public_key_path(public_key)
    elsif published?
      status_tag("published", class: "warning")
    elsif submitted_at
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

  def published_at
    return if invalid?

    if published? || signed?
      object.published_at
    else
      link_to "Publish", publish_admin_form_answer_path(object)
    end
  end

  def user
    if public_key && answers_signature
      link_to public_key.user.name, admin_public_key_path(public_key)
    elsif user = object.user
      link_to user.name, admin_user_path(user)
    end
  end

  def to_s
    user =
      if answers_signature
        public_key.user
      else
        object.user
      end
    [
      "#{form_definition.name} ",
      user ? " by #{user.name}" : "",
    ].join.html_safe
  end
end
