Feature: Create Visits From Template
  In order to create additional predefined visits,
  As authorized user with the permission `create_from_template` for Visit,
  I can create new visits from template via the show patient view.

  Background:
    Given a study "StudyWithout"
    And a center "CenterWithout" with:
      | study | StudyWithout |
    And a patient "PatientWithout" with:
      | center | CenterWithout |
    Given a study "StudyWith" with configuration
      """
      visit_types:
        baseline: 
          description: A simple visit type
          required_series: []
      visit_templates:
        default_preset:
          label: 'Default Preset'
          create_patient_default: true
          only_on_create_patient: true
          visits:
            - number: 1
              type: baseline
              description: Default Visit Description
        additional_preset:
          label: 'Additional Preset'
          hide_on_create_patient: true
          visits:
            - number: 1
              type: baseline
              description: Additional Visit Description
        repeatable_preset:
          label: 'Repeatable Preset'
          repeatable: true
          visits:
            - number: 1
              type: baseline
              description: Repeatable Visit Description
      """
    And a center "CenterWith" with:
      | study | StudyWith |
    And a patient "PatientWith" with:
      | center | CenterWith |

  Scenario: Not authenticated
    When I browse to "/admin/patients/new"
    Then I see "PLEASE SIGN IN"

  Scenario: Not authorized
    Given a patient "FooPatient"
    And I sign in as a user
    And I cannot create patients
    When I browse to "/admin/patients/1/create_visits_from_template"
    Then I see the unauthorized page

  Scenario: No Visit Templates available
    And I sign in as a user
    And I have following abilities:
      | Patient | read, update, create       |
      | Visit   | read, create_from_template |
    When I browse to patient "PatientWithout"
    And I don't see "Visits From Template"
  
  @javascript
  Scenario: Create Available Visit Templates
    And I sign in as a user
    And I have following abilities:
      | Patient | read, update, create       |
      | Visit   | read, create_from_template |
    When I browse to patient "PatientWith"
    And I click link "Visits From Template"
    When I select "Repeatable Preset" from "From Template"
    Then I see "Repeatable Visit Description"
    When I click the "Create Visits" button
    Then I see "Visits created successfully."
    When I browse to "/admin/visits"
    Then I see "Repeatable Visit Description"

  @javascript
  Scenario: Create Existing non-repeatable Visit Templates
    And I sign in as a user
    And I have following abilities:
      | Patient | read, update, create       |
      | Visit   | read, create_from_template |
    When I browse to patient "PatientWith"
    And I click link "Visits From Template"
    When I select "Additional Preset" from "From Template"
    Then I see "Additional Visit Description"
    When I click the "Create Visits" button
    When I browse to patient "PatientWith"
    And I click link "Visits From Template"
    When I select "Additional Preset" from "From Template"
    Then I see "Additional Visit Description"
    When I click the "Create Visits" button
    Then I see "Visits with the same visit number for this patient already exist and selected visit template is not repeatable."

