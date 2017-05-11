Feature: User Audit Trail
  As authorized user,
  I want to see only relevant versions for a user.

  Scenario:
    Given a role "Test Role" with permissions:
      | Version | read |
    And I sign in as a user with role "Test Role"
    When I browse to user "testuser"
    And I click link "Audit Trail" in "#title_bar"
    Then I see "Test User"
    And I see "Test Role"
    And I see "User role"
