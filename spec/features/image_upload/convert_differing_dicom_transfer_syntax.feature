Feature: Convert differing DICOM transfer syntax
  In order to ensure compatibility with OsiriX plugin client-side anonymization,
  all images are saved as little endian dicom files upon upload before ERICA anonymization.

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
      | Visit       | read                              |

  Scenario: Implicit is converted to Explicit Little Endian
    Given I sign in as a user with role "Image Manager"
    When I browse to image_upload page
    Then I see "FooStudy"
    And I see "FooCenter"
    And I see "FooPatient"
    When I select test dicom file "dicom_samples/implicit_mr_16bit_mono2.dcm" for "Choose Directory"
    Then I see "implicit_mr_16bit_mono2"
    When I select image series "implicit_mr_16bit_mono2" for upload
    And I click the "Upload Image Series" button
    Then I see "Upload complete!"
    When I browse to image_series list
    And I click "Metadata" in "implicit_mr_16bit_mono2" row
    Then another window is opened
    And I see "1.2.840.10008.1.2.1" in "TransferSyntax" row
 
  Scenario: Explicit Big Endian is converted to Explicit Little Endian
    Given I sign in as a user with role "Image Manager"
    When I browse to image_upload page
    Then I see "FooStudy"
    And I see "FooCenter"
    And I see "FooPatient"
    When I select test dicom file "dicom_samples/explicit-big-endian_us_8bit_rgb.dcm" for "Choose Directory"
    Then I see "explicit-big-endian"
    When I select image series "explicit-big-endian" for upload
    And I click the "Upload Image Series" button
    Then I see "Upload complete!"
    When I browse to image_series list
    And I click "Metadata" in "explicit-big-endian" row
    Then another window is opened
    And I see "1.2.840.10008.1.2.1" in "TransferSyntax" row

  Scenario: JPEG Lossy is converted to Explicit Little Endian
    Given I sign in as a user with role "Image Manager"
    When I browse to image_upload page
    Then I see "FooStudy"
    And I see "FooCenter"
    And I see "FooPatient"
    When I select test dicom file "dicom_samples/explicit_mr_jpeg-lossy_mono2.dcm" for "Choose Directory"
    Then I see "explicit_mr_jpeg-lossy_mono2"
    When I select image series "explicit_mr_jpeg-lossy_mono2" for upload
    And I click the "Upload Image Series" button
    Then I see "Upload complete!"
    When I browse to image_series list
    And I click "Metadata" in "explicit_mr_jpeg-lossy_mono2" row
    Then another window is opened
    And I see "1.2.840.10008.1.2.1" in "TransferSyntax" row
    
  Scenario: JPEG Lossless is converted to Explicit Little Endian
    Given I sign in as a user with role "Image Manager"
    When I browse to image_upload page
    Then I see "FooStudy"
    And I see "FooCenter"
    And I see "FooPatient"
    When I select test dicom file "dicom_samples/explicit_ct_jpeg-lossless-nh_mono2.dcm" for "Choose Directory"
    Then I see "explicit_ct_jpeg-lossless-nh_mono2"
    When I select image series "explicit_ct_jpeg-lossless-nh_mono2" for upload
    And I click the "Upload Image Series" button
    Then I see "Upload complete!"
    When I browse to image_series list
    And I click "Metadata" in "explicit_ct_jpeg-lossless-nh_mono2" row
    Then another window is opened
    And I see "1.2.840.10008.1.2.1" in "TransferSyntax" row

  Scenario: RLE is converted to Explicit Little Endian
    Given I sign in as a user with role "Image Manager"
    When I browse to image_upload page
    Then I see "FooStudy"
    And I see "FooCenter"
    And I see "FooPatient"
    When I select test dicom file "dicom_samples/explicit_mr_rle_mono2.dcm" for "Choose Directory"
    Then I see "explicit_mr_rle_mono2"
    When I select image series "explicit_mr_rle_mono2" for upload
    And I click the "Upload Image Series" button
    Then I see "Upload complete!"
    When I browse to image_series list
    And I click "Metadata" in "explicit_mr_rle_mono2" row
    Then another window is opened
    And I see "1.2.840.10008.1.2.1" in "TransferSyntax" row
    
  Scenario: JPEG2K is converted to Explicit Little Endian
    Given I sign in as a user with role "Image Manager"
    When I browse to image_upload page
    Then I see "FooStudy"
    And I see "FooCenter"
    And I see "FooPatient"
    When I select test dicom file "dicom_samples/implicit_us_jpeg2k-lossless-mono2-multiframe.dcm" for "Choose Directory"
    Then I see "implicit_us_jpeg2k-lossless-mono2-multiframe"
    When I select image series "implicit_us_jpeg2k-lossless-mono2-multiframe" for upload
    And I click the "Upload Image Series" button
    Then I see "Upload complete!"
    When I browse to image_series list
    And I click "Metadata" in "implicit_us_jpeg2k-lossless-mono2-multiframe" row
    Then another window is opened
    And I see "1.2.840.10008.1.2.1" in "TransferSyntax" row
