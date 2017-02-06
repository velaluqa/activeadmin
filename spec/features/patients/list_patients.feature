Feature: List Patients
  In order to see which patients exist,
  As authorized user,
  I want to list all patients that are accessible by me.

  Scenario: Unauthorized
    Given I sign in as a user
    And I cannot read patients
    When I browse to "/admin/patients"
    Then I see the unauthorized page

  Scenario: Image Import Role System-Wide
    Given a patient "FooPatient"
    And I sign in as a user
    And I have following abilities:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
    When I browse to "/admin/patients"
    Then I see "FooPatient"

  Scenario: Image Import Role Scoped to Study
    Given a study "FooStudy"
    And a center "FooCenter" with:
      | study | FooStudy |
    And a patient "FooPatient" with:
      | center | FooCenter |
    Given I sign in as a user with role scoped to Study "FooStudy"
    And I have following abilities:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
    When I browse to "/admin/patients"
    Then I see "FooPatient"

  Scenario: Image Import Role Scoped to Center
    Given a center "FooCenter"
    And a patient "FooPatient" with:
      | center | FooCenter |
    Given I sign in as a user with role scoped to Center "FooCenter"
    And I have following abilities:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
    When I browse to "/admin/patients"
    Then I see "FooPatient"

  Scenario: Image Import Role Scoped to Patient
    Given a patient "FooPatient":
    And a patient "BarPatient":
    And I sign in as a user with role scoped to Patient "FooPatient"
    And I have following abilities:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
    When I browse to "/admin/patients"
    Then I see "FooPatient"
    And I don't see "BarPatient"
