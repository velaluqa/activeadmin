guard 'rspec', cmd: 'zeus rspec' do
  watch(/^spec\/.+_spec\.rb$/)
  watch(/^lib\/(.+)\.rb$/) { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb') { 'spec' }
  watch(/^app\/(.+)\.rb$/) { |m| "spec/#{m[1]}_spec.rb" }
  watch(/^app\/(.*)(\.erb|\.slim|\.haml)$/) do |m|
    "spec/#{m[1]}#{m[2]}_spec.rb"
  end
  watch(%r{^app/controllers/(.+)_(controller)\.rb$}) do |m|
    [
      "spec/routing/#{m[1]}_routing_spec.rb",
      "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb",
      "spec/acceptance/#{m[1]}_spec.rb"
    ]
  end
  watch(%r{^spec/support/(.+)\.rb$}) { 'spec' }
  watch('config/routes.rb') { 'spec/routing' }
  watch('app/controllers/application_controller.rb') { 'spec/controllers' }
  watch(%r{^app/views/(.+)/.*\.(erb|slim|haml)$}) do |m|
    "spec/features/#{m[1]}_spec.rb"
  end
end

guard 'cucumber', command_prefix: 'zeus', bundler: false do
  watch(%r{^features/.+\.feature$})
  watch(%r{^features/support/.+$}) { 'features' }
  watch(%r{^features/step_definitions/(.+)_steps\.rb$}) do |m|
    Dir[File.join("**/#{m[1]}.feature")][0] || 'features'
  end
end
