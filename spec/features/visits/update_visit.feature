Feature: Update Visit
  In order to adjust visit details,
  As authorized user (update visit),
  I can update a visit.

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
    And a visit "10000" for "FooPatient"
    And a role "Image Manager" with permissions:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
      | Visit   | read, update, create |

  Scenario: Not logged in
    When I browse to edit visit "10000"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user
    And I cannot create patients
    When I browse to edit visit "10000"
    Then I see the unauthorized page

  Scenario: Change Visit Type
    Given I sign in as a user with role "Image Manager"
    When I browse to edit visit "10000"
    Then I see "Edit Visit"
    When I select "baseline" from "Visit type"
    And I click the "Update Visit" button
    Then I am redirected to visit "10000"
    And I see "Visit Type baseline"
    And I see "Visit was successfully updated"

  Scenario: Change Visit Number
    Given I sign in as a user with role "Image Manager"
    When I browse to edit visit "10000"
    Then I see "Edit Visit"
    When I fill in "10001" for "Visit number"
    And I click the "Update Visit" button
    Then I am redirected to visit "10001"
    And I see "Visit Number 10001"
    And I see "Visit was successfully updated"

  Scenario: Change Visit Description
    Given I sign in as a user with role "Image Manager"
    When I browse to edit visit "10000"
    Then I see "Edit Visit"
    When I fill in "Some Description" for "Description"
    And I click the "Update Visit" button
    Then I am redirected to visit "10000"
    And I see "Description Some Description"
    And I see "Visit was successfully updated"
