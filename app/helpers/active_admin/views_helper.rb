module ActiveAdmin::ViewsHelper
  def cart_item_url(item)
    case item[:type]
    when :image_series then admin_image_series_path(item[:id])
    when :visit then admin_visit_path(item[:id])
    when :patient then admin_patient_path(item[:id])
    when :center then admin_center_path(item[:id])
    when :study then admin_study_path(item[:id])
    end
  end
end
