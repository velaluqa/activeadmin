Feature: Resend Confirmation Mail
  In order to retry if the confirmation mail was not received by the user,
  As authorized user for `create user`,
  I can trigger a newly sent confirmation mail manually.

  Background:
    Given a role "Authorized" with permissions:
     | User | read, create |
    And a role "Unauthorized" with permissions:
     | User | read |
    And a user "authorized.user" with role "Authorized" 
    And a user "unauthorized.user" with role "Unauthorized"
    And an unconfirmed user "confirmable.user" with:
      | email | confirm_me@email.com | 

  Scenario: Not allowed if unauthorized
    When I sign in as user "unauthorized.user"
    And I browse to "/admin/users" 
    Then I see "UNCONFIRMED" in "confirmable.user" row
    When I click "View" in "confirmable.user" row
    Then I don't see "Resend confirmation" 
    When I browse to resend_confirmation user "confirmable.user"
    Then I see "Not Authorized"

  Scenario: Not allowed for confirmed users
    When I sign in as user "authorized.user" 
    And I browse to "/admin/users"
    Then I see "CONFIRMED AT" in "unauthorized.user" row
    When I click "View" in "unauthorized.user" row
    Then I don't see "Resend confirmation" 

  Scenario: Success for unconfirmed users
    When I sign in as user "authorized.user" 
    And I browse to "/admin/users"
    Then I see "UNCONFIRMED" in "confirmable.user" row
    When I click "View" in "confirmable.user" row
    Then I see "Resend confirmation" 
    When I click "Resend confirmation"
    Then I see "The user will receive another confirmation e-Mail shortly." 
    Then user "confirmable.user" received 2 mails with subject "Confirmation instructions"
  