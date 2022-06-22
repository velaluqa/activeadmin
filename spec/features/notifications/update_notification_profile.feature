Feature: Update Notification Profile
  In order to manage who receives notifications for which change,
  As authorized user for `update Notification Profile`,
  I can update existing notification profiles.
  
  Scenario: Unauthorized
    Given a role "Unauthorized" with permissions:
      | NotificationProfile | read |
    And a user "unauthorized.user" with role "Unauthorized"
    And an email template "Test Template"
    And a notification profile "My Profile" with:
      | user_recipients | unauthorized.user | 
    When I sign in as user "unauthorized.user"
    And I browse to NotificationProfiles list
    Then I don't see "Edit" in "My Profile" row

  Scenario: Authorized
    Given a role "Authorized" with permissions:
      | NotificationProfile | read, update |
    And a user "authorized.user" with role "Authorized"
    And a user "other.user"
    And an email template "Test Template"
    And a notification profile "My Profile" with:
      | user_recipients | authorized.user | 
    When I sign in as user "authorized.user"
    And I browse to NotificationProfiles list
    Then I see "My Profile"
    When I click "Edit" in "My Profile" row
    Then I see "Add Filter"
    When I fill in "Title" with "New Profile Name"
    And I click "Update Notification profile"
    Then I see "New Profile Name"
