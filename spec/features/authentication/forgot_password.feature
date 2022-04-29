# user_requirement: 
# user_role: Unauthenticated Registered User
# goal: Recover password in case it is forgotten or unknown
# category: Authentication
# components:
#   - authentication
@js
Feature: Recover Password
   In order to gain access even if I have forgot my password, 
   as registered user, 
   I can reset my password via confirming my registered e-mail address.

   Functional Requirement:

   - log the request password change action to the audit trail
   - log the change password action to the audit trail

  Background:
    Given a user "h.maulwurf" with:
      | password | correctpassword      |
      | email    | h.maulwurf@email.com |


  Scenario: Unknown email address
    When I browse to the login page
    And  I request a password reset for "unknown@email.com" 
    Then I see "not found" 


  Scenario: Success
    When I browse to the login page
    And  I request a password reset for "h.maulwurf@email.com" 
    Then I see "You will receive an email with instructions on how to reset your password in a few minutes." 
    When I click "Change My Password" in the "Reset password instructions" e-mail sent to "h.maulwurf@email.com"
    Then another window is opened
    And I see "CHANGE YOUR PASSWORD"
    When I reset my password to "newpassword"
    Then I see "Your password has been changed successfully. You are now signed in."
    When I sign out
    And I sign in as "h.maulwurf" with password "newpassword"
    Then I see "Signed in successfully"