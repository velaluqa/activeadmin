Feature: List Visits
  In order to perform image management or quality control,
  As authorized user to list visits,
  I want to see a list of all visits.

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

  Scenario: Not logged in
    When I browse to visits list
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user
    And I cannot create patients
    When I browse to visits list
    Then I see the unauthorized page

  Scenario: Study-selected
    Given I sign in as a user with role "Image Manager"
    When I browse to study "FooStudy"
    And I click link 'Select'
    And I browse to visits list
    Then I see "FooPatient 10000"
    And I don't see "BarPatient 20000"

  Scenario: All visits
    Given I sign in as a user with role "Image Manager"
    When I browse to visits list
    Then I see "FooPatient 10000"
    And I see "BarPatient 20000"
