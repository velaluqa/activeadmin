require 'schema_validation/study_validator'

describe SchemaValidation::StudyValidator do
  let!(:config_yaml) { <<YAML }
domino_integration:
  dicom_tags:
    - tag: '0406,1010'
      label: Some DICOM Tag
image_series_properties:
  - id: some_property
    type: string
    label: Some Property
visit_types:
  baseline:
    description: Some simple visit type
    required_series:
      series1:
        tqc:
          - id: bool_check
            type: bool
            label: Bool Check
          - id: dicom_check1
            type: dicom
            label: DICOM Number Check
            dicom_tag: '0500,0010'
            expected: 20
          - id: dicom_check2
            type: dicom
            label: DICOM Formula Check
            dicom_tag: '0500,0010'
            expected: 'fomula'
          - id: dicom_check3
            type: dicom
            label: DICOM List Check
            dicom_tag: '0500,0010'
            expected:
              - val1
              - val2
              - val3
    mqc:
      - id: mqc_check1
        type: bool
        label: mQC Check
visit_templates:
  first_template:
    label: 'My Visit Template'
    repeatable: true
    hide_on_create_patient: yes
    visits:
      - number: 1
        type: baseline
        description: 'Some description'
  second_template:
    visits:
      - number: 1
        type: baseline
YAML
  let!(:config) { YAML.load(config_yaml) }
  let!(:validator) { SchemaValidation::StudyValidator.new }

  it 'validates for valid config' do
    expect(validator.validate(config)).to be_empty
  end

  describe 'validating visit templates' do
    it 'validates existence of visit types' do
      config['visit_templates']['first_template']['visits'] << {
        'number' => 2,
        'type'   => 'baseline2'
      }
      expect(validator.validate(config)).not_to be_empty
      expect(validator.validate(config).map(&:to_s)).to include("[/visit_templates/first_template/visits/1] Visit type not found in map of /visit_types")
    end

    it 'validates uniqueness of visit number' do
      config['visit_templates']['first_template']['visits'] << {
        'number' => 1,
        'type'   => 'baseline'
      }
      expect(validator.validate(config)).not_to be_empty
      expect(validator.validate(config).map(&:to_s)).to include("[/visit_templates/first_template/visits/1/number] '1': is already used at '/visit_templates/first_template/visits/0/number'.")
    end

    it 'validates existence of only one `create_patient_default`' do
      config['visit_templates']['third_template'] = {
        'create_patient_default' => true,
        'visits' => [{'number' => 1, 'type' => 'baseline'}]
      }
      config['visit_templates']['fourth_template'] = {
        'create_patient_default' => true,
        'visits' => [{'number' => 1, 'type' => 'baseline'}]
      }
      expect(validator.validate(config)).not_to be_empty
      expect(validator.validate(config).map(&:to_s)).to include("[/visit_templates/fourth_template] Already defined `create_patient_default` for visit template in /visit_templates/third_template")
    end

    it 'validates existence of only one `create_patient_enforce`' do
      config['visit_templates']['third_template'] = {
        'create_patient_enforce' => true,
        'visits' => [{'number' => 1, 'type' => 'baseline'}]
      }
      config['visit_templates']['fourth_template'] = {
        'create_patient_enforce' => true,
        'visits' => [{'number' => 1, 'type' => 'baseline'}]
      }
      expect(validator.validate(config)).not_to be_empty
      expect(validator.validate(config).map(&:to_s)).to include("[/visit_templates/fourth_template] Already defined `create_patient_enforce` for visit template in /visit_templates/third_template")
    end
  end
end
