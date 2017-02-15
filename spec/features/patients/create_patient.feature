Feature: Create Patient
  In order to add new patients to centers,
  As authorized user,
  I want to create patients with specific subject_id.

  Scenario: Not logged in
    When I browse to "/admin/patients/new"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user
    And I cannot create patients
    When I browse to "/admin/patients/new"
    Then I see the unauthorized page

  Scenario: Image Import Role System-Wide
    Given a study "FooStudy"
    And a center "FooCenter" with:
      | study | FooStudy |
    And I sign in as a user
    And I have following abilities:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
    When I browse to "/admin/patients/new"
    Then I see "New Patient"
    When I select "FooCenter" from "Center"
    And I fill in "FooPatient" for "Subject"
    And I click the "Create Patient" button
    Then I am redirected to patient "FooPatient"
    And I see "Patient was successfully created"

  Scenario: Image Import Role Scoped to Study
    Given a study "FooStudy"
    And a center "FooCenter" with:
      | study | FooStudy |
    Given I sign in as a user with role scoped to Study "FooStudy"
    And I have following abilities:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
    When I browse to "/admin/patients/new"
    Then I see "New Patient"
    When I select "FooCenter" from "Center"
    And I fill in "FooPatient" for "Subject"
    And I click the "Create Patient" button
    Then I am redirected to patient "FooPatient"
    And I see "Patient was successfully created"

  Scenario: Image Import Role Scoped to Center
    Given a study "FooStudy"
    And a center "FooCenter" with:
      | study | FooStudy |
    Given I sign in as a user with role scoped to Center "FooCenter"
    And I have following abilities:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
    When I browse to "/admin/patients/new"
    Then I see "New Patient"
    When I select "FooCenter" from "Center"
    And I fill in "FooPatient" for "Subject"
    And I click the "Create Patient" button
    Then I am redirected to patient "FooPatient"
    And I see "Patient was successfully created"

  # Scenario: Image Import Role Scoped to Patient
  #   Given a patient "FooPatient":
  #   And a patient "BarPatient":
  #   And I sign in as a user with role scoped to Patient "FooPatient"
  #   And I have following abilities:
  #     | Study   | read                 |
  #     | Center  | read, update         |
  #     | Patient | read, update, create |
  #   When I browse to "/admin/patients"
  #   Then I see "FooPatient"
  #   And I don't see "BarPatient"


