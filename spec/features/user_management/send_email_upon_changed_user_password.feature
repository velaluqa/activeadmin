Feature: Send e-Mail Upon Changed User Password
  In order to allow the user to intervene if the password of their account was changed,
  As a user with an account,
  I want to be informed about the change of my password via e-mail.
  
  Scenario: Send e-mail
    Given a role "User Manager" with permissions:
     | User | manage |
    And a user "other.user" with:
     | email | my@email.com |
    And a user "admin.user" with role "User Manager"
    When I sign in as user "admin.user"
    And I change the password of "other.user" to "new.password"
    Then I receive an e-mail to "my@email.com" with subject "Password Changed"

