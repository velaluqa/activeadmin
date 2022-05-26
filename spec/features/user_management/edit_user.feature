Feature: Update Users
  In order to perform user managment,
  As authorized user for user update,
  I can update a user's information.

  Background:
    Given a role "User Manager" with permissions:
      | User | read, update |
    And a user "authorized.user" with:
      | name | Alex Authorized |
    And user "authorized.user" belongs to role "User Manager"
    And a role "Unauthorized" with permissions:
      | User | read |
    And a user "other.user" with:
      | name  | Udo Unathorized |
      | email | udo@email.com   |
    And user "other.user" belongs to role "Unathorized"

  Scenario: Unauthorized to update a user
    When I sign in as user "other.user"
    And I browse to users list
    Then I don't see "Edit" in "Alex Authorized" row
  
  Scenario: Authorized to update a user
    When I sign in as user "authorized.user"
    And I browse to users list
    Then I see "Edit" in "other.user" row
    When I click "Edit" in "other.user" row
    And I fill in "Name" with "Chris Unauthorized"
    And I click the "Update User" button
    Then I see "User was successfully updated"
    When I browse to users list
    Then I see a row with "Chris Unauthorized"