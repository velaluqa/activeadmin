Feature: Confirm User Manually
  In order to allow a user to access the system quickly even if confirmation mail did not work (e.g. in case of e-mailing problems),
  As authorized user for `user/confirm`,
  I want to confirm a user account manually in the ERICA user interface.

  Background:
    Given a role "Authorized" with permissions:
      | User | read, confirm_mail |
    And a role "Unauthorized" with permissions:
     | User | read |
    And a user "authorized.user" with role "Authorized" 
    And a user "confirmed.unauthorized.user" with role "Unauthorized"
    And an unconfirmed user "confirmable.user" with:
      | email | confirm_me@email.com |

  Scenario: Unauthorized
    When I sign in as user "confirmed.unauthorized.user" 
    And I browse to users list
    And I click "View" in "confirmable.user" row
    Then I don't see "Confirm e-mail address" in "Confirmed" row

  Scenario: Cannot confirm already confirmed user
    When I sign in as user "authorized.user" 
    And I browse to users list
    And I click "View" in "confirmed.unauthorized.user" row
    Then I don't see "Confirm e-mail address" in "Confirmed" row

  Scenario: Confirm another user manually
    When I sign in as user "authorized.user" 
    And I browse to users list
    And I click "View" in "confirmable.user" row
    Then I see "Confirm e-mail address" in "Confirmed" row
    When I click "Confirm e-mail address" in "Confirmed" row
    Then I see "confirmable.user" in "Username" row
    And I see "CONFIRMED" in "Confirmed" row