Feature: Split multi-frame DICOM files
  In order to work-around reader client limitations with multi-frame dicom files,
  As authorized user for `upload image series`,
  I can upload multi-frame DICOM files and they are split into single frames in a background job.

  Background:
    Given a study "FooStudy" with configuration
      """
      visit_types: {}
      image_series_properties: []
      """
    And a center "FooCenter" with:
      | study | FooStudy |
      | code  |        1 |
    And a patient "FooPatient" for "FooCenter"
    And a role "Image Manager" with permissions:
      | Study       | read         |
      | Center      | read         |
      | Patient     | read         |
      | Visit       | read         |
      | ImageSeries | read, upload |

  Scenario: Successful split of multi-frame upload
    When I sign in as a user with role "Image Manager"
    And I browse to image_upload page
    Then I see "FooStudy"
    And I see "FooCenter"
    And I see "FooPatient"
    When I select test dicom file "multiframe_same_series_uid/compressed_multiframe_1.dcm" for "Choose Directory"
    Then I see "compressed_multiframe_1"
    When I select image series "compressed_multiframe_1" for upload
    And I click the "Upload Image Series" button
    Then I see "Upload complete!"
    When I browse to BackgroundJob list
    Then I see "Split multi-frame DICOM upload compressed_multiframe_1"
    And I wait for all jobs to finish
    When I browse to image_series list
    Then I see a row for "compressed_multiframe_1" with the following columns:
      | Files       | 10 files |
      | Image Types | DICOM    |
