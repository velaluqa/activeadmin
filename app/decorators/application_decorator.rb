class ApplicationDecorator < Draper::Decorator
  delegate :to_xml, :as_json, to: :object

  def status_tag(status, options = {})
    ActiveAdmin::Views::StatusTag.new.status_tag(status, options)
  end
end
