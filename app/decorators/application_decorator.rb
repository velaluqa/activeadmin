class ApplicationDecorator < Draper::Decorator
  def status_tag(status, options = {})
    ActiveAdmin::Views::StatusTag.new.status_tag(status, options)
  end
end
