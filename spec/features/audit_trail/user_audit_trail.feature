Feature: User Audit Trail
  To investigate changes to a certain user,
  As authorized user,
  I want to see only this users changes, the relevant user roles and roles.

  Scenario: User-specific Audit Trail
    Given a role "Test Role" with permissions:
       | Version | read |
    And I sign in as a user with role "Test Role"
    When I browse to user "testuser"
    And I click link "Audit Trail" in "#title_bar"
    Then I see "Test User"
    And I see "Test Role"
    And I see "ASSIGNED"


