ActiveAdmin.register_page 'Viewer Cart' do
  menu :priority => 23

  page_action :start, :method => :get do
    current_user.ensure_authentication_token!

    if(session[:viewer_cart].nil?)
      flash[:error] = 'Your viewer cart is empty.'
      redirect_to :action => :index
      return
    end

    @wado_query_urls = session[:viewer_cart].map do |item|
      case item[:type]
      when :image_series then wado_query_image_series_url(item[:id], :format => :xml, :authentication_token => current_user.authentication_token)
      when :visit then wado_query_visit_url(item[:id], :format => :xml, :authentication_token => current_user.authentication_token)
      when :patient then wado_query_patient_url(item[:id], :format => :xml, :authentication_token => current_user.authentication_token)
      when :center then wado_query_center_url(item[:id], :format => :xml, :authentication_token => current_user.authentication_token)
      when :study then wado_query_study_url(item[:id], :format => :xml, :authentication_token => current_user.authentication_token)
      else nil
      end
    end
    @wado_query_urls.reject! {|url| url.nil? }

    render 'admin/shared/weasis_webstart.jnpl', :layout => false, :content_type => 'application/x-java-jnlp-file'
  end
end
