class PharmTraceERICASiteTitle < ActiveAdmin::Views::SiteTitle
  def build(*args)
    super(*args)

    unless(session[:selected_study_name].nil?)
      text_node ' :: '
      span class: 'aa_selected_study' do
        text_node 'Study: '+session[:selected_study_name]
      end
    end
  end
end
