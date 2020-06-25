@js
Feature: Read Medical Quality Control
  In order to ensure quality of visit,
  As authorized user for read_mqc for a visit,
  I want to read existing answers of the current mQC results.

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
      | patient    | TestPatient         |
      | visit_type | baseline            |
      | state      | complete_tqc_passed |
    And an image_series "TestSeries" with:
      | image_count |              1 |
      | patient     |    TestPatient |
      | visit       |          10000 |
      | state       | visit_assigned |
    And visit "10000" has required series "SPECT" assigned to "TestSeries"
    And a role "Image Manager" with permissions:
      | Study   | read                     |
      | Center  | read, update             |
      | Patient | read, update, create     |
      | Visit   | read, read_tqc, read_mqc |
    And visit "10000" required series "SPECT" has tQC with:
      | acceptable | passed |
    And visit "10000" has mQC with:
      | acceptable | passed |

  Scenario: Not logged in
    When I browse to mqc_results visit "10000"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot read_mqc visits
    When I browse to visits list
    Then I don't see a column "mQC State"
    And I don't see a column "mQC Date"
    And I don't see a column "mQC User"
    And I don't see a row with "10000" and the following columns:
      | mQC State | PERFORMED, PASSED |
    When I browse to show visit "10000"
    Then I don't see "mQC Results"
    And I don't see "M Qc State PERFORMED, PASSED"
    When I browse to mqc_results visit "10000"
    Then I see the unauthorized page

  Scenario: Authorized
    Given I sign in as a user with role "Image Manager"
    When I browse to visits list
    Then I see a column "mQC State"
    And I see a column "mQC Date"
    And I see a column "mQC User"
    And I see a row with "10000" and the following columns:
      | mQC State | PERFORMED, PASSED |
    When I browse to show visit "10000"
    Then I see "M Qc State PERFORMED, PASSED"
    Then I see "mQC Results"
    When I click link "mQC Results"
    Then I see "MQC DETAILS"
    And I see "Visit State COMPLETE, T QC OF ALL SERIES PASSED"
    And I see "Medical Assessment PERFORMED, PASSED"
    And I see "Acceptable? PASS"
