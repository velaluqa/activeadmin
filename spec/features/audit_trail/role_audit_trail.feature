Feature: User Audit Trail
  To investigate changes to a certain user,
  As authorized user,
  I want to see only this users changes, the relevant user roles and roles.

  Scenario: Scoped Audit Trail
    Given a role "Test Role" with permissions:
       | Version | read |
       | Role    | read |
    And I sign in as a user with role "Test Role"
    When I browse to role "Test Role"
    And I click link "Audit Trail" in "#title_bar"
    Then I see "Role Test Role"
    And I see "CREATE"


