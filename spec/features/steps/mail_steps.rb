step 'I open the mail inbox' do
  Sidekiq::Worker.drain_all
  visit("http://mailcatcher-test:1080")
end

step 'I receive an e-mail to :string with subject :string' do |email, subject|
  step "I open the mail inbox"
  step "I see \"#{subject}\" in \"#{email}\" row"
end

step 'I open the mail to :string with subject :string' do |recipient, subject|
  within("tr", text: recipient) do
    page.find("td", text: subject).click
  end
end

step 'I click the link :string within the mail' do |link_text|
  within_frame(page.find("iframe")) do
    page.find_link(link_text).click
  end
end

step 'I click :string in the :string e-mail sent to :string' do |link_text, subject, recipient|
  step 'I open the mail inbox'
  step "I open the mail to \"#{recipient}\" with subject \"#{subject}\""
  step "I click the link \"#{link_text}\" within the mail"
end
