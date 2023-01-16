Feature: Upload Non-DICOM Files
  In order to attach other file formats to patients,
  As authorized user for `upload image series`,
  I can upload non-DICOM file formats.

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

  Scenario: Upload Images file formats (jpg, gif, png, tiff, svg)     
    When I sign in as a user with role "Image Manager"
    And I browse to image_upload page
    When I provide directory "upload/images" for "Choose Directory"
    And I select following series for upload:
      | test.jpg  |
      | test.gif  |
      | test.png  |
      | test.tiff |
      | test.svg  |
    And I click "Upload Image Series"
    Then I see "Upload complete"
    When I browse to image_series list
    Then I see "JPG" in "test.jpg" row
    And I see "GIF" in "test.gif" row
    And I see "PNG" in "test.png" row
    And I see "TIFF" in "test.tiff" row
    And I see "SVG" in "test.svg" row

  Scenario: Upload Video file formats (mp4, avi, mov)
    When I sign in as a user with role "Image Manager"
    And I browse to image_upload page
    When I provide directory "upload/videos" for "Choose Directory"
    And I select following series for upload:
      | test.mp4 |
      | test.mov |
      | test.avi |
    And I click "Upload Image Series"
    Then I see "Upload complete"
    When I browse to image_series list
    Then I see "MP4" in "test.mp4" row
    And I see "AVI" in "test.avi" row
    And I see "MOV" in "test.mov" row

  Scenario: Upload PDFs file formats (pdf)
    When I sign in as a user with role "Image Manager"
    And I browse to image_upload page
    When I provide file "test.pdf" for "Choose Directory"
    And I select following series for upload:
      | test.pdf |
    And I click "Upload Image Series"
    Then I see "Upload complete"
    When I browse to image_series list
    Then I see "PDF" in "test.pdf" row

  Scenario: Upload MS Office file formats (docx, doc, xlsx, xls, pptx, ppt)
    When I sign in as a user with role "Image Manager"
    And I browse to image_upload page
    When I provide directory "upload/msoffice" for "Choose Directory"
    And I select following series for upload:
      | test.docx |
      | test.doc  |
      | test.xlsx |
      | test.xls  |
      | test.pptx |
      | test.ppt  |
    And I click "Upload Image Series"
    Then I see "Upload complete"
    When I browse to image_series list
    Then I see "DOCX" in "test.docx" row
    # TODO: And I see "PPT" in "test.doc " row
    And I see "XLSX" in "test.xlsx" row
    # TODO: And I see "XLS" in "test.xls " row
    And I see "PPTX" in "test.pptx" row
    # TODO: And I see "PPT" in "test.ppt " row
