step 'an email template :string' do |name|
  options = { name: name }

  # table.to_a.each do |attribute, value|
  #   options[attribute.to_sym] = value

  #   if attribute == 'user_recipients'
  #     options[:users] = value.split(",").map(&:strip).map do |username|
  #       User.where(username: username).first
  #     end
  #   end
  # end

  create(:email_template, options)
end

step 'a notification profile :string with:' do |name, table|
  options = { title: name }

  table.to_a.each do |attribute, value|
    if attribute == 'user_recipients'
      options[:users] = value.split(",").map(&:strip).map do |username|
        User.where(username: username).first
      end
    else
      options[attribute.to_sym] = value
    end
  end

  create(:notification_profile, options)
end
