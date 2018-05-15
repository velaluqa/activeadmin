Feature: Create Visits From Template
  In order to create additional predefined visits,
  As authorized user with the permission `create_from_template` for Visit,
  I can create new visits from template via the show patient view.

  Background:
    Given a study "StudyWithout"
    And a center "CenterWithout" for "StudyWithout"
    And a patient "PatientWithout" for "CenterWithout"
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
    And a center "CenterWith" for "StudyWith"
    And a patient "PatientWith" for "CenterWith"
    Given a role "Image Manager" with permissions:
      | Patient | read, update, create       |
      | Visit   | read, create_from_template |

  Scenario: Not authenticated
    When I browse to "/admin/patients/new"
    Then I see "PLEASE SIGN IN"

  Scenario: Not authorized
    Given I sign in as a user with all permissions
    But I cannot create_from_template visits
    When I browse to patient "PatientWith"
    And I don't see "Visits From Template"
    When I browse to create_visits_from_template patient "PatientWithout"
    Then I see the unauthorized page

  Scenario: No Visit Templates available
    Given I sign in as a user with role "Image Manager"
    When I browse to patient "PatientWithout"
    And I don't see "Visits From Template"
  
  @javascript
  Scenario: Create Available Visit Templates
    Given I sign in as a user with role "Image Manager"
    When I browse to patient "PatientWith"
    And I click link "Visits From Template"
    When I select "Additional Preset" from "From Template"
    Then I see "Additional Visit Description"
    When I click the "Create Visits" button
    Then I see "Visits created successfully."
    When I browse to "/admin/visits"
    Then I see "Additional Visit Description"

  @javascript
  Scenario: Create non-repeatable visit template repeatedly
    Given I sign in as a user with role "Image Manager"
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

  @javascript
  Scenario: Create repeatable visit template repeatedly
    Given I sign in as a user with role "Image Manager"
    When I browse to patient "PatientWith"
    And I click link "Visits From Template"
    When I select "Repeatable Preset" from "From Template"
    Then I see "Repeatable Visit Description"
    When I click the "Create Visits" button
    When I browse to patient "PatientWith"
    And I click link "Visits From Template"
    When I select "Repeatable Preset" from "From Template"
    Then I see "Repeatable Visit Description"
    When I click the "Create Visits" button
    Then I see "Visits created successfully."
    When I browse to "/admin/visits"
    Then I see "PatientWith 1 Repeatable Visit Description baseline"
    And I see "PatientWith 1.1 Repeatable Visit Description baseline"

