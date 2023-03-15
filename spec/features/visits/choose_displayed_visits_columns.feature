Feature: Choose displayed columns
  In order to reduce the amount of unnecessary cluttering info,
  As authorized user,
  I want to choose the columns that are displayed to me.

  Background:
      Given a study "FooStudy"
    And a center "FooCenter" for "FooStudy"
    And a patient "FooPatient" for "FooCenter"
    And a visit "10000" for "FooPatient"
    Given a study "BarStudy"
    And a center "BarCenter" for "BarStudy"
    And a patient "BarPatient" for "BarCenter"
    And a visit "20000" for "BarPatient"
    And a role "Image Manager" with permissions:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
      | Visit   | read                 |

  Scenario: Successfully change columns of visits page
    Given I sign in as a user with all permissions
    When I browse to visits page
    Then I see the following columns:
    | Patient | Visit Number | Description | Visit Type | Visit Date | State | mQC State | mQC Date | mQC User | Tags |
    Then I click link "View Columns"
    Then I click button "Clear Selected"
    And I check "visit_date"
    And I check "mqc_state"
    When I click button "Submit"
    Then I don't see the following columns:
    | Patient | Visit Number | Description  | Visit Type | State | mQC Date | mQC User | Tags |
    And I see the following columns:
    | Visit Date | mQC State |
    Then I click link "View Columns"
    And I uncheck "visit_date"
    And I uncheck "mqc_state"
    When I click button "Submit"
    Then I see the following columns:
     | Patient | Visit Number | Description | Visit Type | Visit Date | State | mQC State | mQC Date | mQC User | Tags |