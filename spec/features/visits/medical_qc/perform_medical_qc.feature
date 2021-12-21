# user_requirement: 
# user_role: Authenticated User
# goal: Perform medical quality control
# category: Quality Control
# components:
#   - visit
#   - mqc
@js
Feature: Perform Medical Quality Control
  In order to ensure quality of assigned image series for visit,
  As authorized user for perform_mqc for a visit,
  I want to perform answer defined question catalog for a required series.

  Background:
    Given a study "TestStudy" with configuration
      """
      visit_types:
        baseline: 
          description: A simple visit type
          required_series:
            SPECT:
              tqc:
                - id: acceptable
                  label: Acceptable?
                  type: bool
          mqc:
            - id: acceptable
              label: Acceptable?
              type: bool
      image_series_properties: []
      """
    And a center "TestCenter" for "TestStudy"
    And a patient "TestPatient" for "TestCenter"
    And a visit "10000" with:
      | patient    | TestPatient |
      | visit_type | baseline    |
    And an image_series "TestSeries" with:
      | image_count |              1 |
      | patient     |    TestPatient |
      | visit       |          10000 |
      | state       | visit_assigned |
    And visit "10000" has required series "SPECT" assigned to "TestSeries"
    And a role "Image Manager" with permissions:
      | Study   | read                                  |
      | Center  | read, update                          |
      | Patient | read, update, create                  |
      | Visit   | read, read_tqc, perform_mqc, read_mqc |
    And visit "10000" required series "SPECT" has tQC with:
      | acceptable | passed |
    # And visit "10000" has mQC with:
    #   | acceptable | passed |

  Scenario: Not logged in
    When I browse to mqc_form visit "10000"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot perform_mqc visits
    When I browse to show visit "10000"
    Then I don't see "Perform mQC"
    When I browse to mqc_form visit "10000"
    Then I see the unauthorized page

  Scenario: Success; Medical QC positive
    Given I sign in as a user with role "Image Manager"
    When I browse to show visit "10000"
    Then I see a row with "SPECT" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PASSED     |
    When I click link "Perform mQC"
    Then I see "Perform mQC"
    When I select "Pass" from "Acceptable?"
    And I click "Save mQC Results"
    Then I see "M Qc State PERFORMED, PASSED"

  Scenario: Success; Medical QC negative
    Given I sign in as a user with role "Image Manager"
    When I browse to show visit "10000"
    Then I see a row with "SPECT" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PASSED     |
    When I click link "Perform mQC"
    Then I see "Perform mQC"
    When I select "Fail" from "Acceptable?"
    When I fill in "Comment" with "Some explanation"
    And I click "Save mQC Results"
    Then I see "M Qc State PERFORMED, ISSUES PRESENT"
