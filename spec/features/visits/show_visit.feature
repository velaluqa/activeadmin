Feature: Show Visit
  In order to perform image management,
  As authorized user for show visit,
  I want to see all visit details and respective required series in a table.

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
    And a visit "10000" with:
      | patient     | FooPatient           |
      | visit_type  | baseline             |
      | description | Visit Extraordinaire |
    And a role "Image Manager" with permissions:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
      | Visit   | read                 |

  Scenario: Not logged in
    When I browse to visit "10000"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user
    And I cannot read visits
    When I browse to visit "10000"
    Then I see the unauthorized page

  Scenario: Show visit
    Given I sign in as a user with role "Image Manager"
    When I browse to visit "10000"
    Then I see "Patient 7FooPatient"
    Then I see "Visit Number 10000"
    Then I see "Description Visit Extraordinaire"
    Then I see "Visit Type baselineCCC"
    Then I see "State INCOMPLETE, NOT AVAILABLE"
