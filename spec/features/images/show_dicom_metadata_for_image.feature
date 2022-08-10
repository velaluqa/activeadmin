Feature: Show DICOM metadata for image
  In order to access information inside of the DICOM files header,
  As authorized user for read_dicom_metadata,
  I want to display all DICOM attributes of a selected image.

  Background:
    Given an image_series "IS"
    And a DICOM image for image series "IS"
    And a role "Authorized" with permissions:
      | ImageSeries | read, read_dicom_metadata |
    And a user "authorized.user" with role "Authorized"

  Scenario: Unauthorized
    Given a role "Unauthorized" with permissions:
      | ImageSeries | read |
    And a user "unauthorized.user" with role "Unauthorized"
    When I sign in as user "unauthorized.user"
    And I browse to image_series list
    And I click "1 file" in "IS" row 
    Then I don't see "Metadata"
    And I browse to image_series list
    And I click "1 file" in "IS" row 
    And I click "View" in "IS" row
    Then I don't see "DICOM Metadata"
    When I browse to dicom_metadata Image "IS#1"
    Then I see "You are not authorized to perform this action"

  Scenario: Open metadata from images list
    When I sign in as user "authorized.user"
    And I browse to image_series list
    And I click "1 file" in "IS" row 
    # And I debug
    Then I see "Metadata"
    When I click "Metadata" in "IS" row
    Then another window is opened
    And I see "(0010,0010) PatientName"

  Scenario: Open metadata from image series view
    When I sign in as user "authorized.user"
    And I browse to image_series list
    And I click "1 file" in "IS" row 
    And I click "View" in "IS" row
    And I click "DICOM Metadata"
    Then I see "(0010,0010) PatientName"

  Scenario: Show root DICOM attributes
    When I sign in as user "authorized.user"
    And I browse to dicom_metadata for Image "IS#1"
    Then I see "(0010,0010) PatientName"

  Scenario: Show nested DICOM attributes
    When I sign in as user "authorized.user"
    And I browse to dicom_metadata for Image "IS#1"
    Then I see "(0040,0275) RequestAttributesSequence"
    And I see "Item 0"
    And I see "(0040,0007) ScheduledProcedureStepDescription"
