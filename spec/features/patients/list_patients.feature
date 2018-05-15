Feature: List Patients
  In order to see which patients exist,
  As authorized user,
  I want to list all patients that are accessible by me.

  Background:
    Given a study "FooStudy"
    And a center "FooCenter" for "FooStudy"
    And a patient "FooPatient" for "FooCenter"
    And a patient "BarPatient" for "FooCenter"
    And a role "Image Manager" with permissions:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot read patients
    When I browse to patients list
    Then I see the unauthorized page

  Scenario: Image Import Role System-Wide
    When I sign in as a user with role "Image Manager"
    And I browse to "/admin/patients"
    Then I see "FooPatient"

  Scenario: Image Import Role Scoped to Study
    When I sign in as a user with role "Image Manager" scoped to study "FooStudy"
    And I browse to "/admin/patients"
    Then I see "FooPatient"

  Scenario: Image Import Role Scoped to Center
    When I sign in as a user with role "Image Manager" scoped to center "FooCenter"
    And I browse to "/admin/patients"
    Then I see "FooPatient"

  Scenario: Image Import Role Scoped to Patient
    When I sign in as a user with role "Image Manager" scoped to patient "FooPatient"
    And I browse to "/admin/patients"
    Then I see "FooPatient"
    And I don't see "BarPatient"
