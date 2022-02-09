class CreateFormAnswers < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :form_answers, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.uuid :form_definition_id, index: true, null: false
      t.uuid :configuration_id, index: true, null: false
      t.text :signing_reason, null: true
      t.references :public_key, comment: <<~COMMENT
        Public key used for signatures.
      COMMENT
      t.jsonb :answers, comment: <<~COMMENT
        Answers to the form.
      COMMENT
      t.string :answers_signature, comment: <<~COMMENT
        RSA Signature via private part of `public_key`.
      COMMENT
      t.jsonb :annotated_images, comment: <<~COMMENT
        List of annotated images including their checksum.
      COMMENT
      t.string :annotated_images_signature, comment: <<~COMMENT
        RSA Signature via private part of `public_key`.
      COMMENT
      t.boolean :is_test_data, null: false, default: false
      t.boolean :is_obsolete, null: false, default: false
      t.datetime :signed_at
      t.datetime :submitted_at
      t.timestamps
    end
  end
end
