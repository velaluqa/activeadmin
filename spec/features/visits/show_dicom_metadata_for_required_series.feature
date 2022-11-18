Feature: Show DICOM metadata for required series
  In order to access information inside of the DICOM files header,
  As authorized user for read_dicom_metadata,
  I want to display all DICOM attributes of the first image of the required series.

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
    And a visit "TestVisit" with:
      | patient     | FooPatient           |
      | visit_type  | followup             |
      | description | Visit Extraordinaire |
    And an image_series "TestSeries" with:
      | patient     |    FooPatient       |
      | visit       |    TestVisit        |
      | state       | visit_assigned |
    And a DICOM image for image series "TestSeries"
    And visit "TestVisit" has required series "SPECT_1" assigned to "TestSeries"
    And a role "Authorized" with permissions:
      | ImageSeries    | read, read_dicom_metadata |
      | Visit          | read                      |
      | RequiredSeries | read                      |
    And a user "authorized.user" with role "Authorized"

  Scenario: Unauthorized
    Given a role "Unauthorized" with permissions:
      | ImageSeries    | read |
      | Visit          | read |
      | RequiredSeries | read |
    And a user "unauthorized.user" with role "Unauthorized"
    When I sign in as user "unauthorized.user"
    And I browse to visit "TestVisit"
    Then I don't see "DICOM Metadata"
    When I browse to dicom_metadata ImageSeries "TestSeries"
    Then I see "You are not authorized to perform this action"

  Scenario: Open metadata from visit view
    When I sign in as user "authorized.user"
    And I browse to visit "TestVisit"
    Then I see "DICOM Metadata"
    When I click "DICOM Metadata"
    And I see "PatientName"
