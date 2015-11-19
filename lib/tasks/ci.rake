namespace :ci do
  task :prepare do
    mkdir_p 'tmp/ci'
    mkdir_p 'reports'
  end

  namespace :test do
    task units: ['ci:prepare'] do
      sh 'COVERAGE=true bundle exec rspec --require spec_helper -f html -o reports/unit.html -f JUnit -o tmp/ci/rspec_report.xml'
    end

    task features: ['ci:prepare'] do
      sh 'COVERAGE=true bundle exec cucumber --format html --out reports/features.html --format json --out tmp/ci/cucumber_report.json'
    end
  end
  task test: ['ci:test:units', 'ci:test:features']

  namespace :report do
    task :code_climate do
      sh 'bundle exec rubycritic app lib config/initializers --path reports/code_climate || true'
    end

    task :code_style do
      sh 'bundle exec rubocop --require rubocop/formatter/checkstyle_formatter --rails --fail-level F --format offenses --format RuboCop::Formatter::CheckstyleFormatter --out tmp/ci/rubocop_report.xml --format html --out reports/code_style.html || true'
    end

    task :rails_best_practices do
      sh 'bundle exec rails_best_practices -f html --with-textmate --output-file reports/rails_best_practices.html . || true'
    end

    task :rails_security do
      sh 'bundle exec brakeman --format html --output reports/rails_security.html || true'
    end
  end

  task report: [
    'ci:report:code_climate',
    'ci:report:code_style',
    'ci:report:rails_best_practices',
    'ci:report:rails_security'
  ]

  namespace :generate do
    task :docs do
      sh 'bundle exec yard -o reports/doc'
    end
  end

  task generate: ['ci:generate:docs']
end

task ci: [
  'ci:prepare',
  'ci:test',
  'ci:report',
  'ci:generate:docs'
]
