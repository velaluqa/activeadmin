step 'I open the mail inbox' do
  Sidekiq::Worker.drain_all
  visit("http://mailcatcher-test:1080")
end

step 'I receive an e-mail to :string with subject :string' do |email, subject|
  step "I open the mail inbox"
  step "I see \"#{subject}\" in \"#{email}\" row"
end
