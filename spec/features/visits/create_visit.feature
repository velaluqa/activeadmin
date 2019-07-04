Feature: Create Visits
  In order to perform image managment and quality control,
  As authorized user for visit creation,
  I can create visits for a patient.

  Background:
    Given a study "FooStudy" with configuration
      """
      visit_types:
        baseline:
          description: A simple visit type
          required_series: []
        followup:
          description: A simple visit type
          required_series: []
      """
    And a center "FooCenter" for "FooStudy"
    And a patient "FooPatient" for "FooCenter"
    And a role "Image Manager" with permissions:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
      | Visit   | read, update, create |

  Scenario: Not logged in
    When I browse to "/admin/visits/new"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot create visits
    When I browse to visits page
    Then I don't see "New Visit"
    When I browse to "/admin/visits/new"
    Then I see the unauthorized page

  Scenario: Image Manager Role System-Wide
    Given I sign in as a user with role "Image Manager"
    When I browse to visits page
    Then I see "New Visit"
    When I click link "New Visit"
    Then I see "New Visit"
    When I select "FooPatient" from "Patient"
    And I fill in "Visit number" with "10000"
    And I click the "Create Visit" button
    Then I am redirected to visit "10000"
    And I see "Visit was successfully created"

  Scenario: Image Manager Role Scoped to Study
    Given I sign in as a user with role "Image Manager" scoped to study "FooStudy"
    When I browse to visits page
    Then I see "New Visit"
    When I click link "New Visit"
    Then I see "New Visit"
    When I select "FooPatient" from "Patient"
    And I fill in "Visit number" with "10000"
    And I click the "Create Visit" button
    Then I am redirected to visit "10000"
    And I see "Visit was successfully created"

  Scenario: Image Manager Role Scoped to Center
    Given I sign in as a user with role "Image Manager" scoped to center "FooCenter"
    When I browse to visits page
    Then I see "New Visit"
    When I click link "New Visit"
    Then I see "New Visit"
    When I select "FooPatient" from "Patient"
    And I fill in "Visit number" with "10000"
    And I click the "Create Visit" button
    Then I am redirected to visit "10000"
    And I see "Visit was successfully created"
