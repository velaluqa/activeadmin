Feature: Delete Patients
  In order to remove patients that are false or obsolete,
  As authorized user for deletion of patients,
  I can delete a patient.

  Background:
    Given a patient "Test Patient"
    And a role "Authorized Role" with permissions:
      | Patient  | read, destroy        |
      | Version  | read                 |

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot destroy patients
    When I browse to patients list
    Then I don't see a "Delete" link in row for "Test Patient"
    When I browse to patient "Test Patient"
    Then I don't see "Delete Patient"

  Scenario: Delete from index list page saves comment for audittrail
    When I sign in as a user with role "Authorized Role"
    And I browse to patients list
    Then I see a row with "Test Patient"
    When I click link "Delete"
    And I provide "This is a comment" for browser prompt and confirm
    And I browse to patients list
    Then I don't see a row with "Test Patient"
    When I click "Audit Trail" in the navigation menu
    And I click "View" in the first "Patient" row
    Then I see "This is a comment" in "Comment" row

  Scenario: Delete from show page saves comment for audittrail
    When I sign in as a user with role "Authorized Role"
    And I browse to patient "Test Patient"
    And I click link "Delete Patient"
    And I provide "This is a comment" for browser prompt and confirm
    And I browse to patients list
    Then I don't see a row with "Test Patient"
    When I click "Audit Trail" in the navigation menu
    And I click "View" in the first "Patient" row
    Then I see a row with "This is a comment"