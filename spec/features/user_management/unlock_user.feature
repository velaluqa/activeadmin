Feature: Unlock User
  In order to unlock a locked user,
  As authorized user,
  I can unlock a user.

  Background:
     Given a role "User Manager" with permissions:
       | User    | read, unlock |
     And a user "authorized.user" with:
      | name | Alex Authorized |
     And user "authorized.user" belongs to role "User Manager"
    
  Scenario: Authorised to unlock a user
     Given a locked user "locked.user"
     When I sign in as user "authorized.user"
     And I browse to users list
     Then I see a row with "locked.user"
     When I click "View" in "locked.user" row
     Then I see "Unlock"
     When I click "Unlock"
     Then I see "User unlocked"
