Feature: Recognize multi-frame DICOM files as separate image series
  In order to have separate image series which can then be assigned to different required series,
  the image upload dialog recognizes multi-frame files as separate image series.

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

  @focus
  Scenario: Correct identification of multi-frame image files as separate image series 
    When I sign in as a user with role "Image Manager"
    And I browse to image_upload page
    Then I see "FooStudy"
    And I see "FooCenter"
    And I see "FooPatient"
    When I select DICOM directory "multiframe_same_series_uid" for "Choose Directory"
    Then I see "compressed_multiframe_1"
    And I see "compressed_multiframe_2"
    When I select image series "compressed_multiframe_1" for upload
    And I select image series "compressed_multiframe_2" for upload
    And I click the "Upload Image Series" button
    Then I see "Upload complete!"
    When I browse to image_series list
    And I click "Metadata" in "compressed_multiframe_1" row
    Then another window is opened
    And I see "999.999.94827453" in "SeriesInstanceUID" row
    When I close the current window
    And I browse to image_series list
    And I click "Metadata" in "compressed_multiframe_2" row
    Then another window is opened
    And I see "999.999.94827453" in "SeriesInstanceUID" row

