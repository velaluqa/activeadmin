namespace :erica do
  namespace :seed do
    desc 'Create an app administrator'
    task :root_user, [:username, :email, :encrypted_password] => [:environment] do |_, args|
      if args[:username].blank?
        puts 'No username given, aborting. Use `rake erica:seed:root_user[username(, email)]`'
        next
      end

      user = User.where(username: args[:username]).first_or_initialize
      if user.new_record?
        puts "Creating application administrator '#{user.username}' with password 'change'."
      else
        puts "Account exists. Making sure '#{user.username}' is an unlocked application administrator with password 'change'."
      end
      user.name = args[:username]
      user.email = args[:email] || "admin@pharmtrace.com"
      user.is_root_user = true
      user.locked_at = nil
      user.password_changed_at = 1.year.from_now
      if args[:encrypted_password]
        user.encrypted_password = args[:encrypted_password]
      else
        user.password = 'change'
        user.password_confirmation = 'change'
      end
      user.confirmed_at = DateTime.now
      user.save!
    end

    task roles: :environment do
      # TODO: Add ERICA remote specific role permission seeds.
      def create_role(title, permissions = {})
        return if Role.where(title: title).exists?
        puts "Creating role '#{title}'"
        FactoryBot.create(:role,
                           title: title,
                           with_permissions: permissions[:with_permissions])
      end

      create_role('Manager',
                  with_permissions: {
                    BackgroundJob => :manage,
                    Sidekiq => :manage,
                    Study  => :manage,
                    Center => :manage,
                    Patient => :manage,
                    ImageSeries => :manage,
                    Image => :manage,
                    User => :manage,
                    UserRole => :manage,
                    PublicKey => :manage,
                    Role => :manage,
                    Visit => :manage,
                    Version => :manage
                  })
      create_role('Image Import', with_permissions: {
                    Study => %i[read],
                    Center => %i[read update create],
                    Patient => %i[read update create],
                    ImageSeries => %i[upload reassign_patient assign_visit]
                  })
      create_role('Image Manager', with_permissions: {
                    Study => %i[read update create],
                    Center => %i[read update create],
                    Patient => %i[read update create],
                    ImageSeries => %i[read comment upload reassign_patient assign_visit],
                    Visit => %i[read create create_from_template comment assign_required_series read_tqc perform_tqc read_mqc perform_mqc]
                  })
      create_role('Medical QC', with_permissions: {
                    Study => %i[read],
                    Center => %i[read],
                    Patient => %i[read],
                    Visit => %i[read assign_required_series read_mqc perform_mqc]
                  })
      create_role('Audit', with_permissions: {
                    Study => :read,
                    Center => :read,
                    Patient => :read,
                    ImageSeries => :read,
                    Image => :read,
                    Visit => :read,
                    Version => :read
                  })
      create_role('Read-Only', with_permissions: {
                    Study => :read,
                    Center => :read,
                    Patient => :read,
                    ImageSeries => :read,
                    Image => :read,
                    Visit => :read
                  })
    end

    task demo: :environment do
      def populate_study(options = {})
        center_count       = options[:centers] || 150
        patient_count      = options[:patients] || 200
        image_series_count = options[:image_series] || 200
        image_count        = options[:images] || 150

        progress = ProgressBar.create(
          format: "Populating #{options[:study].name}: %a %E %P% Processed: %c from %C",
          total: center_count * patient_count * image_series_count * image_count
        )
        center_count.times do
          center = FactoryBot.create(:center, study: options[:study])

          patient_count.times do
            patient = FactoryBot.create(:patient, center: center)

            image_series_count.times do
              image_series = FactoryBot.create(:image_series, patient: patient)

              image_count.times do
                FactoryBot.create(:image, image_series: image_series)

                progress.increment
              end
            end
          end
        end
      end

      @study1 = FactoryBot.create(:study, name: 'Small Study')
      populate_study(
        study: @study1,
        centers: 10,
        patients: 10,
        image_series: 10,
        images: 10
      )
      @study2 = FactoryBot.create(:study, name: 'Medium Study')
      populate_study(
        study: @study2,
        centers: 25,
        patients: 25,
        image_series: 25,
        images: 25
      )
      @study3 = FactoryBot.create(:study, name: 'Large Study')
      populate_study(
        study: @study3,
        centers: 50,
        patients: 50,
        image_series: 50,
        images: 50
      )
    end
  end
end
