Feature: Create Patient
  In order to add new patients to centers,
  As authorized user,
  I want to create patients with specific subject_id.

  Background:
    Given a study "FooStudy"
    And a center "FooCenter" for "FooStudy"
    And a role "Image Manager" with permissions:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |

  Scenario: Not logged in
    When I browse to "/admin/patients/new"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot create patients
    When I browse to patients page
    Then I don't see "New Patient"
    When I browse to "/admin/patients/new"
    Then I see the unauthorized page

  Scenario: Image Import Role System-Wide
    Given I sign in as a user with role "Image Manager"
    When I browse to "/admin/patients/new"
    Then I see "New Patient"
    When I select "FooCenter" from "Center"
    And I fill in "FooPatient" for "Subject"
    And I click the "Create Patient" button
    Then I am redirected to patient "FooPatient"
    And I see "Patient was successfully created"

  Scenario: Image Import Role Scoped to Study
    Given I sign in as a user with role "Image Manager" scoped to study "FooStudy"
    When I browse to "/admin/patients/new"
    Then I see "New Patient"
    When I select "FooCenter" from "Center"
    And I fill in "FooPatient" for "Subject"
    And I click the "Create Patient" button
    Then I am redirected to patient "FooPatient"
    And I see "Patient was successfully created"

  Scenario: Image Import Role Scoped to Center
    Given I sign in as a user with role "Image Manager" scoped to center "FooCenter"
    When I browse to "/admin/patients/new"
    Then I see "New Patient"
    When I select "FooCenter" from "Center"
    And I fill in "FooPatient" for "Subject"
    And I click the "Create Patient" button
    Then I am redirected to patient "FooPatient"
    And I see "Patient was successfully created"


