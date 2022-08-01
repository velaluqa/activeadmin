Feature: Allow viewing recipients for a given resource if notification profiles are triggered only for authorized users
  In order to simulate the recipients of notifications for a given resource,
  As authorized user for viewing recipients of notifications,
  I can view the notification profiles for authorised users.

  Background: 
    Given a role "Authorized" with permissions:
      | NotificationProfile | read, simulate_recipients |
      | Study | read        |
    And a role "Unauthorized" with permissions:
      | NotificationProfile | read |
    And a role "Study Manager" with permissions:
      | Study | read |
    And a user "authorized.user" with role "Authorized"
    And a user "recipient.candidate" with role "Study Manager"
    And a user "unauthorized.candidate" with role "Unauthorized"
    And an email template "Test Template"
    And a notification profile "My Profile" with:
      | triggering_resource | Study |
    And a study "Brain Study"
    And a study "Breast Study"

  Scenario: Unauthorized to simulate recipients
    When I sign in as user "unauthorized.candidate"
    And I browse to NotificationProfiles list
    Then I see "My Profile"
    But I don't see "Simulate recipient" in "My Profile" row
        
  Scenario: Authorised to simulate recipients
    When I sign in as user "authorized.user"
    And I browse to NotificationProfiles list
    Then I see "My Profile"
    When I click "Simulate recipient" in "My Profile" row
    Then I see "SIMULATE RECIPIENTS"
    When I choose "Brain Study" from "Resource"
    And I click "Show Recipients"
    Then I see "recipient.candidate"
    But I don't see "unauthorized.candidate"