Feature: Assign Required Series
  In order simplify the image management process,
  As authorized user for upload, visit assignment and required series assignment,
  I can assign required series directly in the uploader.

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
    And a center "FooCenter" for "FooStudy"
    And a patient "FooPatient" for "FooCenter"
    And a visit "10000" with:
      | patient     | FooPatient           |
      | visit_type  | followup             |
      | description | Visit Extraordinaire |
    And a role "Image Manager" with permissions:
      | Study       | read                         |
      | Center      | read                         |
      | Patient     | read                         |
      | ImageSeries | read, upload, assign_visit   |
      | Visit       | read, assign_required_series |

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

  Scenario: Upload With Assigned Required Series Successful
    Given I sign in as a user with role "Image Manager"
    When I browse to image_upload page
    Then I see "FooStudy"
    And I see "FooCenter"
    And I see "FooPatient"
    When I select a DICOM folder for "Choose Directory"
    Then I see "SCOUT 3-PLANE RT"
    When I select "SCOUT 3-PLANE RT" for upload
    And I select visit "10000" for "SCOUT 3-PLANE RT"
    And I select required series "SPECT_1" for "SCOUT 3-PLANE RT"
    And I click the "Upload Image Series" button
    Then I see "Upload complete!"
    When I browse to image_series list
    Then I see "#10000" in "SCOUT 3-PLANE RT" row
    And I see "SPECT_1" in "SCOUT 3-PLANE RT" row
