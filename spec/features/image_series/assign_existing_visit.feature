Feature: Assign Visit
  In order to mark an image series as candidate for quality control,
  As authorized user that can assign image series to visits,
  I can assign an image series to a visit.

  Background:
    Given a study "FooStudy"
    And a center "FooCenter" for "FooStudy"
    And a patient "FooPatient" for "FooCenter"
    And a visit "10000" with:
      | patient     | FooPatient           |
      | visit_type  | followup             |
      | description | Visit Extraordinaire |
    And an image_series "TestSeries" with:
      | patient | FooPatient |
    And a role "Image Manager" with permissions:
      | Study       | read                 |
      | Center      | read, update         |
      | Patient     | read, update, create |
      | ImageSeries | read, assign_visit   |

  Scenario: Not logged in
    When I browse to assign_visit_form image_series "TestSeries"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot assign_visit image_series
    When I browse to image_series list
    Then I don't see "Assign Visit"
    When I browse to assign_visit_form image_series "TestSeries"
    Then I see the unauthorized page

  Scenario: Assignment Of Existing Visit Successful
    Given I sign in as a user with role "Image Manager"
    When I browse to image_series list
    Then I see "Assign Visit"
    When I click link "Assign Visit"
    Then I see "ASSIGN VISIT"
    When I select "10000" from "Visit"
    And I click the "Assign Visit" button
    Then I am redirected to image_series list
    And I see "#10000"
