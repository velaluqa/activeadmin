Feature: Logout
  In order to end my session within the system and log in as another user,
  As authenticated user,
  I can logout from the navigation bar.

  Scenario: Confirmed user, session stops
    Given a user "confirmed.user"
    When I browse to the login page
    And I try to sign in as "confirmed.user"
    Then I see "Signed in successfully" 
    And I see the navigation menu with entries:
      | Dashboard               |
      | Background Jobs         |
      | Logout                  |
    When I click "Logout" 
    Then I see "You need to sign in before continuing" 
                                                   