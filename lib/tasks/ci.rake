namespace :ci do
  task :prepare do
    mkdir_p 'reports'
    sh 'rm -rf reports/*'
  end

  namespace :test do
    task units: ['ci:prepare'] do
      sh 'COVERAGE=true bundle exec spring rspec --format ValidationReport::RSpec::Formatter --format html -o reports/unit.html --format JUnit -o reports/rspec_report.xml'
    end
  end
  task test: ['ci:test:units']

  namespace :report do
    task :code_climate do
      sh 'bundle exec rubycritic app lib config/initializers --path reports/code_climate --no-browser || true'
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

  task :generate_database_schema_description do
    system("rake db:schema:document > doc/db_schema_description.md")
  end

  task :generate_database_schema_diagram do
    system("bundle exec erd --filetype=png; mv erd.png ./doc/domain_model.png")
  end

  class TemplateRenderer
    def self.empty_binding
      binding
    end

    def self.render(template_content, locals = {})
      b = empty_binding
      locals.each { |k, v| b.local_variable_set(k, v) }

      ERB.new(template_content, nil, '-').result(b)
    end
  end

  task :release_doc => [
         :generate_functional_spec,
         :generate_database_schema_diagram,
         :generate_database_schema_description
       ] do

    load "config/initializers/00_version.rb"

    [
      "functional_specification.md.erb",
      "design_specification.md.erb",
      "operational_qualification_report.md.erb",
      "installation_qualification_report.md.erb",
    ].each do |file|
      vars = {
        date: ENV['SPOOF_DATE'] || Date.today.iso8601.to_s,
        version: ENV['SPOOF_VERSION'] || StudyServer::Application.config.erica_version.join(".")
      }
      md_source = TemplateRenderer.render(File.read("doc/" + file), vars)

      target_dir = "./doc/#{vars[:version]}/"
      FileUtils.mkdir_p(target_dir)
      target_file = target_dir + file.gsub(/(\..*)+$/, '.pdf')

      temp_file = Tempfile.new
      temp_file.write(md_source)
      temp_file.flush

      md_file = target_dir + file.gsub(/(\..*)+$/, '.md')

      File.write(md_file, md_source)

      puts "Generating #{target_file}"

      command = [
        "pandoc",
        md_file,
        "--pdf-engine=xelatex",
        "-f markdown+raw_tex",
        "--data-dir=./doc/tex-junk",
        "--template=./doc/vendor/documentation_latex_template.tex",
        "-o #{target_file}"
      ]
      system(command.join(" "))

      system("ls -la #{temp_file.path}")
    end
  end

  # task :iqs do
  #   {
  #     "7.0.18" => "",

  #   }
  # end

  def collapse_tables(lines)
    out = []
    lines.each do |line|
      if line[0] == "|"
        out[out.length-1] += "\n#{line}"
      else
        out.push(line)
      end
    end
    out
  end

  task :generate_functional_spec do
    column_names = [
      'category',
      'user requirement',
      'functional requirement',
      'intent',
      'permission',
      'components',
      'side effects'
    ]

    specs = Dir['spec/features/**/*.feature'].map do |file|
      puts "Reading #{file} ..."
      content = File.read(file)
      meta = YAML.load(
        content
          .split("\n")
          .map { |line| line =~ /^# (.*)$/ ? $1 : "" }
          .compact
          .join("\n")
      ) || {}
      meta['title'] = content.match(/Feature: (.*)/)[1].strip
      background =
        begin
          background = content.index(/^[ ]*Background:/)
          first_scenario = content.index(/Scenario:/)
          if background
            content[background...first_scenario]
              .match(/Background:(.*)/m)[1]
              .strip
              .split("\n")
              .map(&:strip)
              .reject(&:blank?)
          else
            []
          end
        end

      meta['scenarios'] = content[content.index(/^[ ]*Scenario:/)..-1].split(/Scenario:/).reject(&:blank?).map do |text|
        next if text.blank?
        lines = text.split("\n")
        scenario = {}
        scenario['name'] = lines[0]&.strip
        scenario['steps'] =
          collapse_tables(background) +
          collapse_tables(lines[1..-1].map(&:strip).reject(&:blank?))
        scenario
      end.compact

      meta
    end.reject(&:empty?).sort_by { |meta| "#{meta['category']}#{meta['title']}" }

    file = "doc/functional_requirement_specification.json"
    puts "Writing #{file}"
    File.write(file,JSON.dump(specs))
  end

end

task ci: [
  'ci:prepare',
  'ci:test',
  'ci:report',
  'ci:generate:docs',
  'ci:cleanup'
]
