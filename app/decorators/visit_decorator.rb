class VisitDecorator < ApplicationDecorator
  delegate_all

  include Draper::LazyHelpers

  def mqc_state
    if model.mqc_state_sym == :pending
      status_tag('Pending')
    elsif model.mqc_state_sym == :issues
      status_tag('Performed, issues present', class: 'error')
    elsif model.mqc_state_sym == :passed
      status_tag('Performed, passed', class: 'ok')
    end
  end

  def mqc_configuration
    link_to('Download', download_configuration_at_version_admin_study_path(model.study, config_version: model.mqc_version))
  end

  def state
    if model.state_sym == :incomplete_na
      status_tag('Incomplete, not available')
    elsif model.state_sym == :complete_tqc_passed
      status_tag('Complete, tQC of all series passed', :ok)
    elsif model.state_sym == :incomplete_queried
      status_tag('Incomplete, queried', :warning)
    elsif model.state_sym == :complete_tqc_pending
      status_tag('Complete, tQC not finished', :warning)
    elsif model.state_sym == :complete_tqc_issues
      status_tag('Complete, tQC finished, not all series passed', :error)
    end
  end
end