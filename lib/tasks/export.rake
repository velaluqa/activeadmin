def find_username_by_public_key(pub_key_id)
  return 'No public key id in formanswer.' unless pub_key_id
  pub_key = PublicKey.where(id: pub_key_id).first

  return "No public key found for id #{pub_key_id}." unless pub_key
  return "No user found for public key with id #{pub_key_id}." unless pub_key.user

  pub_key.user.username
end

def extract_image_paths(images)
  return [] unless images
  images.keys
rescue StandardError => e
  puts "Error retrieving image ids #{images.inspect}"
  puts e, e.backtrace
end

def ensure_time(submitted_at)
  case submitted_at
  when Time then submitted_at
  when String then DateTime.parse(submitted_at)
  end
rescue StandardError => e
  puts "#{e} - #{submitted_at.class} as JSON: #{submitted_at.to_json}"
  e.backtrace
end

def generic_filename(options)
  filename = "./form_answers_"
  filename << "case_#{options.case_id}_" if options.case_id
  filename << "session_#{options.session_id}_" if options.session_id
  filename << "patient_#{options.patient_id}_" if options.patient_id
  filename << "#{DateTime.now.strftime('%Y-%m-%d_%H%M')}.csv"
end

namespace :export do
  task form_answers: :environment do |a, b|
    options = OpenStruct.new(
      case_id:             ENV['case'].andand.to_i,
      session_id:          ENV['session'].andand.to_i,
      patient_id:          ENV['patient'].andand.to_i,
      show_first_versions: ENV['show_first_versions'] == 'true',
      filename:            ENV['filename']
    )
    options.filename ||= generic_filename(options)

    CSV.open(options.filename, 'w') do |csv|
      csv << [
        'case_id', 'patient_number', 'case_type', 'annotated_images',
        'field_key', 'field_label', 'previous_answer', 'new_answer',
        'submit_date', 'submit_time', 'username'
      ]

      answers = if options.case_id
                  FormAnswer.where(case_id: options.case_id)
                elsif options.session_id
                  FormAnswer.where(session_id: options.session_id)
                elsif options.patient_id
                  FormAnswer.where(patient_id: options.patient_id)
                else
                  FormAnswer.all
                end

      count = answers.count
      count_len = count.to_s.length
      answers.each_with_index do |answer, i|
        print "\rProcessing #{(i+1).to_s.rjust(count_len, ' ')}/#{count}"
        labels = begin
                   form_config, _, _ = answer.form.andand.full_configuration_at_versions(answer.form_versions)
                   Hash[form_config.map { |conf| [conf['id'], conf['label']] }]
                 rescue StandardError => e
                   puts "\nError retreiving form configuration for form_answer #{answer._id}"
                   puts " - Form-ID: #{answer.form_id}"
                   puts " - Form-Versions: #{answer.form_versions.to_json}"
                   {}
                 end

        # Create a versions array that is easily traversable with
        # Enumerable#each_cons.
        versions = answer.versions.nil? ? [] : answer.versions.clone

        # Not quite clean as of yet. But this is the easiest way to
        # quickly convert all data to the right (expected) formats.
        # Mainly the date format should be correct.
        # TODO: In the FormAnswers model, there should a method
        # correctly saving versions.
        versions << JSON.parse({
                                 'answers' => answer.answers,
                                 'answers_signature' => answer.answers_signature,
                                 'annotated_images' => answer.annotated_images,
                                 'annotated_images_signature' => answer.annotated_images_signature,
                                 'submitted_at' => answer.submitted_at.to_s,
                                 'signature_public_key_id' => answer.signature_public_key_id
                               }.to_json)

        [nil, *versions].each_cons(2) do |pre, new|
          pre_answers = pre.andand['answers']
          new_answers = new.andand['answers']

          # Skip new form_answers that do not have the `answers` property.
          next unless new && new_answers

          new_answers.keys.each do |key|
            # Skip first assignments if not set otherwise via ENV.
            next if pre_answers.nil? && !options.show_first_versions
            # Skip values, that are the same.
            next if pre_answers && pre_answers[key] == new_answers[key]

            submitted_at = ensure_time(new['submitted_at'])
            csv << [
              answer.case_id,
              answer.case.andand.patient.andand.subject_id,
              answer.case.andand.case_type,
              extract_image_paths(new['annotated_images']).to_json,
              key,
              labels[key] || key,
              (pre.nil? ? 'n/A' : pre_answers[key].to_json),
              new_answers[key].to_json,
              submitted_at && submitted_at.strftime('%Y-%m-%d'),
              submitted_at && submitted_at.strftime('%H:%M:%S'),
              find_username_by_public_key(new['signature_public_key_id'])
            ]
          end
        end
      end
    end
    puts "\nFinished writing to #{options.filename}."
  end
end
