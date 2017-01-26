ActiveAdmin.register_page 'Image Upload' do
  menu(parent: 'meta_store', priority: 10)

  content do
    render 'content'
  end
end
