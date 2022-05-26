Feature: Lock due to failed login attempts
  In order to avoid brute force logins,
  As user logging in,
  I lock the account I try to login as after 3 failed logins.

  Scenario: Account locked after 3 attempts
     Given a user "confirmed.user"
     When I browse to the login page
     And I try to sign in as "confirmed.user" 3 times with incorrect password "any.password"
     Then I see "Your account is locked"