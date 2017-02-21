Feature: Create Patient With Visits
  In order to enfore a specific study structure,
  As authorized user,
  I can create patients with predefined set of visits from visit templates configured in the study configuration.

  Background:
    Given a study "StudyWithout" with configuration
      """
      visit_types:
        baseline:
          description: A simple visit type
          required_series: []
      """
    And a center "CenterWithout" for "StudyWithout"
    Given a study "StudyEnforce" with configuration
      """
      visit_types:
        baseline:
          description: A simple visit type
          required_series: []
      visit_templates:
        enforced_preset:
          label: 'Enforced Preset'
          create_patient_enforce: true
          only_on_create_patient: true
          visits:
            - number: 1
              type: baseline
              description: Enforced Visit Description
        additional_preset:
          label: 'Additional Preset'
          hide_on_create_patient: true
          visits:
            - number: 1
              type: baseline
              description: Additional Visit Description
      """
    And a center "CenterEnforce" for "StudyEnforce"
    Given a study "StudyDefault" with configuration
      """
      visit_types:
        baseline:
          description: A simple visit type
          required_series: []
      visit_templates:
        default_preset:
          label: 'Default Preset'
          only_on_create_patient: true
          create_patient_default: true
          visits:
            - number: 1
              type: baseline
              description: Default Visit Description
        optional_preset:
          label: 'Optional Preset'
          visits:
            - number: 1
              type: baseline
              description: Optional Visit Description
        additional_preset:
          label: 'Additional Preset'
          hide_on_create_patient: true
          visits:
            - number: 1
              type: baseline
              description: Additional Visit Description
      """
    And a center "CenterDefault" for "StudyDefault"
    Given a study "StudyOptional" with configuration
      """
      visit_types:
        baseline:
          description: A simple visit type
          required_series: []
      visit_templates:
        optional_preset_1:
          label: 'Option 1 Preset'
          visits:
            - number: 1
              type: baseline
              description: Option 1 Visit Description
        optional_preset_2:
          label: 'Option 2 Preset'
          visits:
            - number: 1
              type: baseline
              description: Option 2 Visit Description
      """
    And a center "CenterOptional" for "StudyOptional"
    Given a role "Image Manager" with permissions:
      | Center  | read                       |
      | Patient | read, update, create       |
      | Visit   | read, create_from_template |
    And a role "Image Reader" with permissions:
      | Center  | read                 |
      | Patient | read, update, create |
      | Visit   | read                 |
  
  Scenario: User cannot create_from_visit, Without Visit Template
    Given I sign in as a user with role "Image Reader"
    And I cannot create_from_template visits
    When I browse to "/admin/patients/new"
    And I select "CenterWithout" from "Center"
    Then I see "No presets for selected center or study available."

  Scenario: User cannot create_from_visit, Default Visit Template
    Given I sign in as a user with role "Image Reader"
    And I cannot create_from_template visits
    When I browse to "/admin/patients/new"
    And I select "CenterDefault" from "Center"
    Then I see "No presets for selected center or study available."

  Scenario: User cannot create_from_visit, Optional Visit Template
    Given I sign in as a user with role "Image Reader"
    And I cannot create_from_template visits
    When I browse to "/admin/patients/new"
    And I select "CenterOptional" from "Center"
    Then I see "No presets for selected center or study available."

  Scenario: User cannot create_from_visit, Enforced Visit Template
    Given I sign in as a user with role "Image Reader"
    And I cannot create_from_template visits
    When I browse to "/admin/patients/new"
    And I select "CenterEnforce" from "Center"
    Then I see "Enforced Visit Description"
    When I fill in "PatientEnforce" for "Subject"
    And I click the "Create Patient" button
    Then I see "Patient was successfully created"
    When I browse to "/admin/visits"
    Then I see "PatientEnforce"
    And I see "Enforced Visit Description"

  Scenario: User can create_from_visit, Without Visit Template
    Given I sign in as a user with role "Image Manager"
    And I can create_from_template visits
    When I browse to "/admin/patients/new"
    And I select "CenterWithout" from "Center"
    Then I see "No presets for selected center or study available."

  Scenario: User can create_from_visit, Enforced Visit Template
    Given I sign in as a user with role "Image Manager"
    And I can create_from_template visits
    When I browse to "/admin/patients/new"
    And I select "CenterEnforce" from "Center"
    Then I see "Enforced Visit Description"
    When I fill in "PatientEnforce" for "Subject"
    And I click the "Create Patient" button
    Then I see "Patient was successfully created"
    When I browse to "/admin/visits"
    Then I see "PatientEnforce"
    And I see "Enforced Visit Description"

  Scenario: User can create_from_visit, Default Visit Template
    Given I sign in as a user with role "Image Manager"
    And I can create_from_template visits
    When I browse to "/admin/patients/new"
    And I select "CenterDefault" from "Center"
    Then I see "Default Preset"
    And I see "Default Visit Description"
    When I fill in "PatientDefault" for "Subject"
    And I click the "Create Patient" button
    Then I see "Patient was successfully created"
    When I browse to "/admin/visits"
    Then I see "PatientDefault"
    And I see "Default Visit Description"

  Scenario: User can create_from_visit, Optional Visit Template
    Given I sign in as a user with role "Image Manager"
    And I can create_from_template visits
    When I browse to "/admin/patients/new"
    And I select "CenterOptional" from "Center"
    When I fill in "PatientOptional" for "Subject"
    And I select "Option 1 Preset" from "From Template"
    Then I see "Option 1 Visit Description"
    When I click the "Create Patient" button
    Then I see "Patient was successfully created"
    When I browse to "/admin/visits"
    Then I see "PatientOptional"
    And I see "Option 1 Visit Description"
