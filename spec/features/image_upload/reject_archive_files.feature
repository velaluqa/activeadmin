Feature: Reject Archive File Uploads
  In order to avoid upload of multiple files not recognizable by the system and having to extract and re-upload them manually,
  As authorized user for 'upload images' 
  I am not allowed to upload any archive files.
  
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

  Scenario: Uploading ZIP is denied
    When I sign in as a user with role "Image Manager"
    And I browse to image_upload page
    When I provide file "test.zip" for "Choose Directory"
    Then I see "test.zip - File type not allowed"
    When I click "OK"
    Then I don't see "test.zip"

  Scenario: Uploading GZIP is denied
    When I sign in as a user with role "Image Manager"
    And I browse to image_upload page
    When I provide file "test.tar.gz" for "Choose Directory"
    Then I see "File type not allowed"
    When I click "OK"
    Then I don't see "test.tar.gz"

  Scenario: Uploading TAR is denied
    When I sign in as a user with role "Image Manager"
    And I browse to image_upload page
    When I provide file "test.tar" for "Choose Directory"
    Then I see "File type not allowed"
    When I click "OK"
    Then I don't see "test.tar"

  Scenario: Uploading 7zip is denied
    When I sign in as a user with role "Image Manager"
    And I browse to image_upload page
    When I provide file "test.7z" for "Choose Directory"
    Then I see "File type not allowed"
    When I click "OK"
    Then I don't see "test.7z"

  Scenario: Uploading RAR is denied
    When I sign in as a user with role "Image Manager"
    And I browse to image_upload page
    When I provide file "test.rar" for "Choose Directory"
    Then I see "File type not allowed"
    When I click "OK"
    Then I don't see "test.rar"
