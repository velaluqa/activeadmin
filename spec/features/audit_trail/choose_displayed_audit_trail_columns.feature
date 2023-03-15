Feature: Choose displayed columns
  In order to reduce the amount of unnecessary cluttering info,
  As authorized user,
  I want to choose the columns that are displayed to me.

  Background:
    Given a role "Test Role" with permissions:
       | Version | read |
       | Center  | read |
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

  Scenario: Successfully change columns of study list
    Given I sign in as a user with all permissions
    When I browse to versions page 
    Then I see the following columns:
    | Timestamp | Item Type | Item | Event | User |
    Then I click link "View Columns"
    Then I click button "Clear Selected"
    And I check "item"
    When I click button "Submit"
    Then I don't see the following columns:
    | Timestamp | Item Type | Event | User |
    And I see the following columns:
    | Item |
    Then I click link "View Columns"
    And I uncheck "item"
    When I click button "Submit"
    Then I see the following columns:
    | Timestamp | Item Type | Item | Event | User |
