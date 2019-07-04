Feature: Image Audit Trail
  To investigate changes to a certain image series,
  As authorized user,
  I want to scope the audit trail to only one image_series and the related images.

  Background:
    Given a role "Test Role" with permissions:
       | Version | read |
       | Image   | read |
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

  Scenario: Image-specific Audit Trail
    When I sign in as a user with role "Test Role"
    And I browse to last defined image
    And I click link "Audit Trail" in "#title_bar"
    Then I see "Image Image #"
    And I don't see "ImageSeries Foo"
    And I don't see "Patient" within "#main_content"
    And I don't see "Visit" within "#main_content"
    And I don't see "Center" within "#main_content"
    And I don't see "Study" within "#main_content"
