# user_requirement: 
# user_role: Authenticated User
# goal: Anonymize DICOM headers 
# category: Image Upload
# components:
#   - image upload
@js
Feature: Anonymize DICOM Headers
  In order adhere to regulatory specifics,
  As authorized user for upload,
  image dicom header information for patients are anonymized.

  Background:
    Given a study "FooStudy" with configuration
      """
      visit_types:
        baseline: 
          required_series: {}
        followup: 
          required_series:
            SPECT_1:
              tqc: []
            SPECT_2:
              tqc: []
      image_series_properties: []
      """
    And a center "FooCenter" with:
      | study | FooStudy |
      | code  |        1 |
    And a patient "FooPatient" for "FooCenter"
    And a role "Image Manager" with permissions:
      | Study       | read                              |
      | Center      | read                              |
      | Patient     | read                              |
      | ImageSeries | read, read_dicom_metadata, upload |
      | Image       | read                              |
      | Visit       | read                              |

  Scenario: Not logged in
    When I browse to image_upload page
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user
    And I can read studies
    And I can read centers
    And I can read patients
    And I cannot upload image_series
    When I browse to image_upload page
    Then I see the unauthorized page

  Scenario: Success
    Given I sign in as a user with role "Image Manager"
    When I browse to image_upload page
    Then I see "FooStudy"
    And I see "FooCenter"
    And I see "FooPatient"
    When I select a DICOM folder for "Choose Directory"
    Then I see "SCOUT 3-PLANE RT"
    When I select image series "SCOUT 3-PLANE RT" for upload
    And I click the "Upload Image Series" button
    And I wait 15 seconds
    Then I see "Upload complete!"
    When I browse to image_series list
    And I click "Metadata" in "SCOUT 3-PLANE RT" row
    Then another window is opened
    And I see "1FooPatient" in "PatientName" row

