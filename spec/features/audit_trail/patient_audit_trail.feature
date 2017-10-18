Feature: Patient Audit Trail
  To investigate changes to a certain patient,
  As authorized user,
  I want to see only to the patient and related image_series, images.

  Background:
    Given a role "Test Role" with permissions:
       | Version | read |
       | Patient | read |
    And a study "FooStudy"
    And a center "FooCenter" with:
      | study | FooStudy |
      | code  |      100 |
    And a patient "FooPatient" for "FooCenter"
    And a visit "10000" with:
      | patient     | FooPatient           |
      | visit_type  | followup             |
      | description | Visit Extraordinaire |
    And an image_series "Foo" with:
      | patient | FooPatient |
      | visit   |      10000 |
    And an image for image series "Foo"

  Scenario: Scoped Audit Trail
    When I sign in as a user with role "Test Role"
    And I browse to patient "FooPatient"
    And I click link "Audit Trail" in "#title_bar"
    Then I see "Image Image #"
    And I see "ImageSeries Foo"
    And I see "Visit 100FooPatient#10000"
    And I see "Patient 100FooPatient"
    And I don't see "Center 100 - FooCenter"
    And I don't see "Study FooStudy"

