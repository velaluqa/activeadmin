namespace :ci do
  task :prepare do
    mkdir_p 'reports'
    sh 'rm -rf reports/*'
  end

  namespace :test do
    task units: ['ci:prepare'] do
      sh 'COVERAGE=true bundle exec spring rspec --require spec_helper -f html -o reports/unit.html -f JUnit -o reports/rspec_report.xml'
    end
  end
  task test: ['ci:test:units']

  namespace :report do
    task :code_climate do
      sh 'bundle exec rubycritic app lib config/initializers --path reports/code_climate || true'
    end

    task :code_style do
      sh 'bundle exec rubocop --require rubocop/formatter/checkstyle_formatter --rails --fail-level F --format offenses --format RuboCop::Formatter::CheckstyleFormatter --out reports/rubocop_report.xml --format html --out reports/code_style.html || true'
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

  task :cleanup do
    sh 'mv -f ./coverage ./reports'
  end
end

task ci: [
  'ci:prepare',
  'ci:test',
  'ci:report',
  'ci:generate:docs',
  'ci:cleanup'
]
