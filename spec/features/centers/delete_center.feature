Feature: Delete Centers
  In order to remove centers that are false or obsolete,
  As authorized user for deletion of centers,
  I can delete a center.

  Background:
    Given a center "Test Center"
    And a role "Authorized Role" with permissions:
      | Center  | read, destroy        |
      | Version | read                 |

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot destroy centers
    When I browse to centers list
    Then I don't see a "Delete" link in row for "Test Center"
    When I browse to center "Test Center"
    Then I don't see "Delete Center"

  Scenario: Delete from index list page saves comment for audittrail
    When I sign in as a user with role "Authorized Role"
    And I browse to centers list
    Then I see a row with "Test Center"
    When I click link "Delete"
    And I provide "This is a comment" for browser prompt and confirm
    And I browse to centers list
    Then I don't see a row with "Test Center"
    When I click "Audit Trail" in the navigation menu
    And I click "View" in the first "Center" row
    Then I see "This is a comment" in "Comment" row

  Scenario: Delete from show page saves comment for audittrail
    When I sign in as a user with role "Authorized Role"
    And I browse to center "Test Center"
    And I click link "Delete Center"
    And I provide "This is a comment" for browser prompt and confirm
    And I browse to centers list
    Then I don't see a row with "Test Center"
    When I click "Audit Trail" in the navigation menu
    And I click "View" in the first "Center" row
    Then I see a row with "This is a comment"