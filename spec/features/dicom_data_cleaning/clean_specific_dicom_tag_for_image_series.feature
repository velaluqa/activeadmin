# user_requirement: 
# user_role: Authenticated User
# goal: Clean specific DICOM tag for image series
# category: Data Cleaning
# components:
#   - DICOM de-identification
#   - data cleaning
@js
Feature: Clean specific DICOM tag for image series
  In order to remove identifying personal information from uploaded DICOM data,
  as authorized user for clean_dicom_metadata for image series,
  I want to select a DICOM tag in the metadata view to execute data cleaning for.
  
  Notes:

  - changed DICOM files should be copied to a backup location before destructive actions are performed

  Background:
    Given a role "Image Manager" with permissions:
      | ImageSeries | read, clean_dicom_metadata |
      | Image       | read                       |

    Given a study "A"
    And a center "A" for "A"
    And a patient "1" for "A"
    And an image series "IS1" for "1"
    And a DICOM image for "IS1" with metadata:
      | 0010,0010 | Not allowed |

    Given a study "B"
    And a center "B" for "B"
    And a patient "2" for "B"
    And an image series "IS2" for "2"
    And a DICOM image for "IS2" with metadata:
      | 0010,0010 | Not allowed |

  Scenario: Unauthorized
    Given a role "Image Reader" with permissions:
      | ImageSeries | read |
      | Image       | read |
    When I sign in as a user with role "Image Reader"
    And I browse to dicom_metadata ImageSeries "IS1"
    Then I see "Not allowed" in "PatientName" row
    But I don't see "clean"

  Scenario: Clean all images of image series
    When I sign in as a user with role "Image Manager"
    And I browse to dicom_metadata ImageSeries "IS1"
    Then I see "Not allowed" in "PatientName" row

    When I hover "clean" in "PatientName" row
    And I click link "clean tag for image series" and confirm
    Then I see "Clean DICOM tag 0010,0010 for image series IS1"
    And I wait for all jobs in "CleanDicomTagWorker" queue

    And I browse to dicom_metadata ImageSeries "IS1"
    Then I see "redacted" in "PatientName" row

    And I browse to dicom_metadata ImageSeries "IS2"
    Then I see "Not allowed" in "PatientName" row

