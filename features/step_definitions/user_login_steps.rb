Given(/^there is a monster$/) do
  @test = FormAnswer.canonical_json_string("Hi")
end

When(/^I attack it$/) do
end

Then(/^it should die$/) do
  expect(@test).to eq "\"Hi\""
end
