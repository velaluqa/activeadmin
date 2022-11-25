Feature: Unassign required series when deleting assigned image series
  In order to test that required series are unassigned after
  deleting assigned image series we want to show that required
  series are unassigned and previous tQC results are removed.

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
      | Study           | read                        |
      | Center          | read, update                |
      | Patient         | read, update, create        |
      | Visit           | read, perform_tqc, read_tqc |
      | RequiredSeries  | read                        |
      | ImageSeries     | read, destroy               |

  Scenario: Unassign required series
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
    When I browse to image_series list
    And I click "Delete" in "TestSeries" row
    And I confirm alert
    When I browse to show visit "10000"
    Then I see "MISSING" in "SPECT_1" row
    