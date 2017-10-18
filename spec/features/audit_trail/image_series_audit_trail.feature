Feature: ImageSeries Audit Trail
  To investigate changes to a certain image series,
  As authorized user,
  I want to scope the audit trail to only one image_series and the related images.

  Background:
    Given a role "Test Role" with permissions:
       | Version     | read |
       | ImageSeries | read |
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
    And I browse to image_series "Foo"
    And I click link "Audit Trail" in "#title_bar"
    Then I see "Image Image #"
    And I see "ImageSeries Foo"
    And I don't see "Patient"
    And I don't see "Visit"
    And I don't see "Patient"
    And I don't see "Center"
    And I don't see "Study"

