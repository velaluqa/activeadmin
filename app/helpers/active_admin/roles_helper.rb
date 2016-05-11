module ActiveAdmin::RolesHelper
  def permissions_matrix_activity(role, subject, activity, options = {})
    render(
      partial: 'permissions_matrix_activity_checkbox',
      locals: {
        activity: activity,
        subject: subject,
        ability: "#{activity}_#{subject.to_s.underscore}",
        checked: role.allows_any?([activity, :manage], subject),
        disabled: options[:disabled] || (activity != :manage && role.allows?(:manage, subject))
      }
    )
  end
end
