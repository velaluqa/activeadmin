Feature: List Patients
  In order to see which patients exist,
  As authorized user,
  I want to list all patients that are accessible by me.

  Scenario: Unauthorized
    Given I sign in as a user
    And I cannot read patients
    When I browse to "/admin/patients"
    Then I see the unauthorized page

  Scenario: Image Import Role
    Given a patient exists:
      | subject_id | FooPatient |
    Given I sign in as a user
    And I have following abilities:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
    When I browse to "/admin/patients"
    Then I see "FooPatient"

