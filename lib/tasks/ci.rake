namespace :ci do
  task :prepare do
    mkdir_p 'tmp/ci'
  end

  task rspec: ['ci:prepare'] do
    sh 'COVERAGE=true bundle exec rspec --require spec_helper -f JUnit -o tmp/ci/rspec_report.xml'
  end

  task cucumber: ['ci:prepare'] do
    sh 'COVERAGE=true bundle exec cucumber --format json --out tmp/ci/cucumber_report.json'
  end

  task :rubycritic do
    sh 'bundle exec rubycritic app lib  --path tmp/ci/code_smell_report'
  end

  task :rails_best_practices do
    sh 'bundle exec rails_best_practices -f html --with-textmate --output-file tmp/ci/rails_best_practices_report.html .; exit 0'
  end

  task :ruby_style_guide do
    sh 'bundle exec rubocop -f html > tmp/ci/ruby_style_guide_report.html .; exit 0'
  end
end

task ci: [
  'ci:prepare',
  'ci:rspec',
  'ci:cucumber',
  'ci:rubycritic',
  'ci:rails_best_practices',
  'ci:ruby_style_guide'
]
