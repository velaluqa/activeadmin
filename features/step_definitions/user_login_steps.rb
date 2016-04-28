Given(/^there is a monster$/) do
  @test = "Hi".inspect
end

When(/^I attack it$/) do
end

Then(/^it should die$/) do
  expect(@test).to eq "\"Hi\""
end
