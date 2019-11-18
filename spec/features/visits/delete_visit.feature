Feature: Delete Visits
  In order to remove visits that are false or obsolete,
  As authorized user for deletion of visits,
  I can delete a visit.

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
      | description | Visit Extraordinaire |
    And a role "Image Manager" with permissions:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
      | Visit   | read, destroy        |

  Scenario: Not logged in
    When I browse to visits list
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot destroy visits
    When I browse to visits list
    Then I don't see "FooPatient 10000 Visit Extraordinaire INCOMPLETE, NOT AVAILABLE PENDING ViewDelete"
    When I browse to visit "10000"
    Then I don't see "Delete Visit"

  Scenario: Successful
    Given I sign in as a user with role "Image Manager"
    When I browse to visits list
    Then I see "FooPatient 10000 Visit Extraordinaire INCOMPLETE, NOT AVAILABLE PENDING ViewDelete"
    When I click link "Delete" and confirm
    Then I don't see "FooPatient 10000 Visit Exreairdubaire"

