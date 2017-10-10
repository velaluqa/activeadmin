ActiveAdmin.register_page 'Not Authorized' do
  controller do
    def authorize_access!; end
  end

  content do
    'You are not authorized to perform this action!'
  end
end
