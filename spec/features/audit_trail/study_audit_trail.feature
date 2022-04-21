# user_requirement: 
# user_role: Authenticated User
# goal: Access filtered audit trail
# category: Audit Trail
# components:
#   - audit trail
Feature: Study Audit Trail
  To investigate changes to a certain study,
  As authorized user,
  I want to see only to the study, related centers, patients, image_series, images.

  Background:
    Given a role "Test Role" with permissions:
       | Version | read |
       | Study   | read |
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
    And a required series "SPECT" for visit "10000" with:
      | image_series | Foo |

  Scenario: Study-specific Audit Trail
    When I sign in as a user with role "Test Role"
    And I browse to study "FooStudy"
    And I click link "Audit Trail" in "#title_bar"
    Then I see "RequiredSeries 100FooPatient#10000 SPECT"
    And I see "Image Foo#1"
    And I see "ImageSeries Foo"
    And I see "Visit 100FooPatient#10000"
    And I see "Patient 100FooPatient"
    And I see "Center 100 - FooCenter"
    And I see "Study FooStudy"

