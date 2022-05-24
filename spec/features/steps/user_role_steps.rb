step("I see checked permission :string for resource :string") do |permission, resource|
  within("li", text: resource) do
    within("span.activity", text: /^#{Regexp.escape(permission)}$/) do
      field = find("input")
      expect(field).to be_checked, "find a checked checkbox for #{resource} permission #{page.text}"
    end
  end
end

step("I see unchecked permission :string for resource :string") do |permission, resource|
  within("li", text: resource) do
    within("span.activity", text: /^#{Regexp.escape(permission)}$/) do
      field = find("input")
      expect(field).not_to be_checked, "find a unchecked checkbox for #{resource} permission #{page.text}"
    end
  end
end

step("I hover over permission :string for resource :string") do |permission, resource|
  within("li", text: resource) do
    permission_element = find("span.hoverable", text: /^#{Regexp.escape(permission)}$/)
    permission_element.hover
  end
end
