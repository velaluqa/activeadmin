# user_requirement: 
# user_role: Authenticated User
# goal: Perform technical quality control
# category: Quality Control
# components:
#   - visit
#   - tqc
@js
Feature: Perform Technical Quality Control
  In order to ensure technical quality of assigned image series,
  As authorized user for `perform_tqc` for a visit,
  I want to perform answer defined question catalog for a required series.

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
              - id: my_question
                label: Custom question
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
    And visit "10000" has required series "SPECT_1" assigned to "TestSeries"
    And a role "Image Manager" with permissions:
      | Study   | read                        |
      | Center  | read, update                |
      | Patient | read, update, create        |
      | Visit   | read, perform_tqc, read_tqc |

  Scenario: Not logged in
    When I browse to tqc_form visit "10000"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot perform_tqc visits
    When I browse to show visit "10000"
    Then I don't see "Perform tQC"
    When I browse to tqc_form visit "10000"
    Then I see the unauthorized page
    
  Scenario: Technical QC passed
    Given I sign in as a user with role "Image Manager"
    When I browse to show visit "10000"
    Then I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PENDING    |
    When I click link "Perform tQC"
    Then I see "Perform tQC for SPECT_1"
    When I select "Pass" for "Custom question"
    And I click button "Save tQC Results"
    Then I see "tQC results saved"
    And I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PASSED     |
    And I see "View tQC results"
    
  Scenario: Automatic DICOM QC failed
    Given I sign in as a user with role "Image Manager"
    When I browse to show visit "10000"
    Then I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PENDING    |
    When I click link "Perform tQC"
    Then I see "Perform tQC for SPECT_1"
    When I select "Fail" for row "Slice thickness acceptable"
    And I click button "Save tQC Results"
    Then I see "A comment is required"
    When I fill in "Comment" with "Some explanation"
    And I click button "Save tQC Results"
    Then I see "tQC results saved"
    And I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES                |
      | tQC State             | PERFORMED, ISSUES PRESENT |

  Scenario: Custom Technical QC failed
    Given I sign in as a user with role "Image Manager"
    When I browse to show visit "10000"
    Then I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PENDING    |
    When I click link "Perform tQC"
    Then I see "Perform tQC for SPECT_1"
    When I select "Fail" for "Custom question"
    And I click button "Save tQC Results"
    Then I see "A comment is required"
    When I fill in "Comment" with "Some explanation"
    And I click button "Save tQC Results"
    Then I see "tQC results saved"
    And I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES                |
      | tQC State             | PERFORMED, ISSUES PRESENT |
