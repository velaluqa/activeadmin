# user_requirement: 
# user_role: Authenticated User
# goal: Clean specific DICOM tag
# category: Data Cleaning
# components:
#   - DICOM de-identification
#   - data cleaning
@js
Feature: Clean specific DICOM tag for study
  In order to remove identifying personal information from uploaded DICOM data,
  as authorized user for clean_dicom_headers for study
  I want to select a DICOM tag in the metadata view and execute data cleaning.
  
  Notes:

  - changed DICOM files should be copied to a backup location before destructive actions are performed

  Background:
    Given a role "Image Manager" with permissions:
      | Study       | clean_dicom_metadata |
      | ImageSeries | read                 |
      | Image       | read                 |

    Given a study "A"
    And a center "A" for "A"

    And a patient "A1" for "A"
    And an image series "IS_A1" for "A1"
    And a DICOM image for "IS_A1" with metadata:
      | 0010,0010 | Not allowed |

    And a patient "A2" for "A"
    And an image series "IS_A2" for "A2"
    And a DICOM image for "IS_A2" with metadata:
      | 0010,0010 | Not allowed |

    Given a study "B"
    And a center "B" for "B"
    And a patient "B1" for "B"
    And an image series "IS_B1" for "B1"
    And a DICOM image for "IS_B1" with metadata:
      | 0010,0010 | Not allowed |

  Scenario: Unauthorized
    Given a role "Image Reader" with permissions:
      | ImageSeries | read |
      | Image       | read |
    When I sign in as a user with role "Image Reader"
    And I browse to dicom_metadata ImageSeries "IS_A1"
    Then I see "Not allowed" in "PatientName" row
    But I don't see "clean"

  Scenario: Authorized for image series, but not for study 
    Given a role "Image Reader" with permissions:
      | ImageSeries | read, clean_dicom_metadata |
      | Image       | read                       |
    When I sign in as a user with role "Image Reader"
    And I browse to dicom_metadata ImageSeries "IS_A1"
    Then I see "Not allowed" in "PatientName" row
    And I see "clean"
    When I hover "clean" in "PatientName" row
    Then I see "clean tag for image series"
    But I don't see "clean tag for study"

  Scenario: Clean all images of study
    When I sign in as a user with role "Image Manager"
    And I browse to dicom_metadata ImageSeries "IS_A1"
    Then I see "Not allowed" in "PatientName" row
    When I browse to dicom_metadata ImageSeries "IS_A2"
    Then I see "Not allowed" in "PatientName" row

    When I hover "clean" in "PatientName" row
    Then I see "clean tag for study"
    When I click link "clean tag for study" and confirm
    Then I see "Clean DICOM tag PatientName (0010,0010) for study A"
    And I wait for all jobs in "CleanDicomTagWorker" queue

    And I browse to dicom_metadata ImageSeries "IS_A1"
    Then I don't see "Not allowed"

    And I browse to dicom_metadata ImageSeries "IS_A2"
    Then I don't see "Not allowed"

    And I browse to dicom_metadata ImageSeries "IS_B1"
    Then I see "Not allowed" in "PatientName" row
