@js
Feature: Read Technical Quality Control Results
  In order to ensure technical quality of assigned image series,
  As authorized user for `read_tqc` for a visit,
  I want to read existing answers for a required series tQC results.

  Background: 
    Given a study "TestStudy" with configuration
      """
      visit_types:
        baseline: 
          description: A simple visit type
          required_series:
            SPECT_1:
              tqc:
              - id: slice_thickness
                label: Slice thickness acceptable (<= 5mm)?
                type: dicom
                dicom_tag: 0018,0050
                expected: x <= 10
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
    And visit "10000" has required series "SPECT_1" assigned to "TestSeries"
    And visit "10000" required series "SPECT_1" has tQC with:
      | slice_thickness | passed         |
      | comment         | Some nice pass |
  Scenario: Not logged in
    When I browse to tqc_results visit "10000" with:
      | required_series_names | SPECT_1 |
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot read_tqc visits
    When I browse to show visit "10000"
    Then I don't see "View tQC results"
    When I browse to tqc_results visit "10000" with:
      | required_series_names | SPECT_1 |
    Then I see the unauthorized page
    
  Scenario: Authorized
    Given a role "Image Manager" with permissions:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
      | Visit   | read, read_tqc       |
    And I sign in as a user with role "Image Manager"
    When I browse to show visit "10000"
    Then I see "SPECT_1 TESTSERIES PASSED"
    And I see "View tQC results"
    When I click link "View tQC results"
    Then I see "tQC results for SPECT_1"
    And I see "State PASSED"


