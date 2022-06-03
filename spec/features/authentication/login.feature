Feature: Login
  In order to authenticate myself against the system,
  As registered user,
  I want to sign in with username and password.
  
  Scenario: Unknown user, shows error
    When I browse to the login page
    And I try to sign in as "unregistered.user"
    Then I see "Invalid Username or password"
  
  Scenario: Unconfirmed user, shows error
    Given unconfirmed user "unconfirmed.user"
    When I browse to the login page
    And I try to sign in as "unconfirmed.user"
    Then I see "You have to confirm your email address before continuing"
  
  Scenario: Locked user, shows error
    Given a locked user "locked.user"
    When I browse to the login page
    And I try to sign in as "locked.user"
    Then I see "Your account is locked"

  Scenario: Confirmed user, authenticates new session
    Given a user "confirmed.user"
    When I browse to the login page
    And I try to sign in as "confirmed.user"
    Then I see "Signed in successfully"

  Scenario: Confirmed user & wrong password, denies access
    Given a user "confirmed.user"
    When I browse to the login page
    And I try to sign in as "confirmed.user" with incorrect password "any.password"
    Then I see "Invalid Username or password"