Feature: Impersonate User
  In order to test the configuration from the point of view of any user account within the system (permissions, user related study configuration, etc),
  As user with permission `impersonate User`,
  I can impersonate another user, which logs me in as this user.

  Background:
    Given a role "Authorized" with permissions:
      | Study   | read              |
      | Center  | read              |
      | Patient | read              |
      | User    | read, impersonate |
    And a user "authorized.user" with:
      | name | Alex Authorized |
    And user "authorized.user" belongs to role "Authorized" 
    And a role "Unauthorized" with permissions:
      | ImageSeries | read |
    And a user "other.user" with:
      | name | Udo Unauthorized |
    And user "other.user" belongs to role "Unauthorized" 

  Scenario: Impersonate check permissions and log out
    When I sign in as user "authorized.user" 
    Then I see the navigation menu for "Alex Authorized" with entries:
      | Studies                                                |
      | Centers                                                |
      | Patients                                               |
      | Users                                                  |
    When I click "Users" in the navigation menu
    Then I see "Impersonate" in "other.user" row
    When I click "Impersonate" in "other.user" row
    Then I see the navigation menu for "Udo Unauthorized" with entries:
      | Image Series |
    But I don't see "Studies" in the navigation menu
    And I don't see "Logout" in the navigation menu
    When I click "Stop Impersonating" in the navigation menu
    Then I see the navigation menu for "Alex Authorized" with entries:
      | Studies    |
      | Centers    |
      | Patients   |
      | Users      |

  Scenario: Unauthorized to impersonate a user
    When I sign in as user "other.user" 
    And I browse to "/admin/users" 
    But I don't see "Impersonate" in "other.user" row
    Then I see the navigation menu for "Udo Unauthorized" with entries:
      | Image Series |
    When I click "Logout" 
    Then I see "You need to sign in before continuing" 
