Feature: Choose displayed columns
  In order to reduce the amount of unnecessary cluttering info,
  As authorized user,
  I want to choose the columns that are displayed to me.

  Background:
  Given a study "TestStudy"
    And a center "TestCenter" for "TestStudy"
    And a patient "TestPatient" for "TestCenter"
    And a visit "1000" for "TestPatient"

  Scenario: Successfully change columns of center list
    Given I sign in as a user with all permissions
    When I browse to center list
    Then I see the following columns:
         | Study | Code | Name | Tags |
    Then I click link "View Columns"
    Then I click button "Clear Selected"
    And I check "name"
    When I click button "Submit"
    Then I don't see the following columns:
        | Study | Code | Tags |
    And I see a column "Name"
    Then I click link "View Columns"
    And I uncheck "name"
    When I click button "Submit"
    Then I see the following columns:
         | Study | Code | Name | Tags |


