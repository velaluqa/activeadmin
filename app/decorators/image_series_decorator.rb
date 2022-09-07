class ImageSeriesDecorator < ApplicationDecorator
  include Draper::LazyHelpers

  delegate_all

  def state
   if model.state_sym == :importing
    status_tag('Importing', class: 'note')
   elsif model.state_sym == :imported
    status_tag('Imported', class: 'error')
   elsif model.state_sym == :visit_assigned
    status_tag('Visit assigned', class: 'warning')
   elsif model.state_sym == :required_series_assigned
    assigned_required_series = model.assigned_required_series.pluck(:name)

    label = '<ul>'
    label += assigned_required_series.map {|ars| '<li>'+ars+'</li>'}.join('')
    label += '</ul>'

    ('<div class="status_tag required_series_assigned ok">'+label+'</div>').html_safe
   elsif model.state_sym == :not_required
    status_tag('Not relevant for read')
   end
  end

  def image_types
    extensions = model.mime_extensions
    if extensions.present?
      status_tag(extensions.join(', '))
    else
      status_tag('NONE')
    end
  end

  def view_in
    result = ''

    result += link_to('Viewer', viewer_admin_image_series_path(model, :format => 'jnlp'), :class => 'member_link')
    result += link_to('Metadata', dicom_metadata_admin_image_series_path(model), :class => 'member_link', :target => '_blank') if model.has_dicom? && can?(:read_dicom_metadata, model)
    result += link_to('Domino', model.lotus_notes_url, :class => 'member_link') unless(model.domino_unid.nil? or model.lotus_notes_url.nil? or Rails.application.config.is_erica_remote)
    if can?(:assign_visit, model)
      result += link_to('Assign Visit', assign_visit_form_admin_image_series_path(model, :return_url => request.fullpath), :class => 'member_link')
    end
    if model.visit && can?(:assign_required_series, model.visit)
      result += link_to('Assign RS', assign_required_series_form_admin_image_series_path(model, :return_url => request.fullpath), :class => 'member_link')
    end

    result.html_safe
  end

  def viewer
    link_to('View in Viewer', weasis_viewer_admin_image_series_path(model, :format => 'jnlp'))
  end

  def import_date
    pretty_format(model.created_at)
  end

  def study_name
    link_to(model.study.name, admin_study_path(model.study)) unless model.study.nil?
  end

  def files
    link_to("#{model.images.count} #{"file".pluralize(model.images.count)}", admin_images_path(:'q[image_series_id_eq]' => model.id))
  end
end
