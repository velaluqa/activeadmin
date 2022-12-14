# user_requirement: 
# user_role: Authenticated User
# goal: Delete a study
# category: Study Management
# components:
#   - study
Feature: Delete Study
  In order to remove studies that are false or obsolete,
  As authorized user for deletion of studies,
  I can delete a study.

  Background:
    Given a study "FooStudy"
    And a role "Image Manager" with permissions:
      | Study   | read, destroy        |
      | Version | read                 |

  Scenario: Not logged in
    When I browse to studies list
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot destroy studies
    When I browse to studies list
    Then I don't see a "Delete" link in row for "FooStudy"
    When I browse to study "FooStudy"
    Then I don't see "Delete Study"

  Scenario: Reject deletion of studies with centers
    Given a center "TestCenter" for "FooStudy"
    And a patient "TestPatient" for "TestCenter"
    When I sign in as a user with role "Image Manager"
    And I browse to studies list
    Then I see a row for "FooStudy" with the following columns:
      | Name          | FooStudy |
      | Configuration | MISSING  |
      | State         | Building |
    When I click link "Delete"
    And I confirm alert
    Then I see "Cannot delete study with centers"
    When I browse to studies list
    Then I see a row with "FooStudy"

  Scenario: Successful
    Given I sign in as a user with role "Image Manager"
    When I browse to studies list
    Then I see a row for "FooStudy" with the following columns:
      | Name          | FooStudy |
      | Configuration | MISSING  |
      | State         | Building |
    When I click link "Delete"
    And I dismiss popup
    Then I see a row with "FooStudy"
    When I click link "Delete"
    And I provide "This is a comment" for browser prompt and confirm
    And I browse to studies list
    Then I don't see a row with "FooStudy"
    When I click "Audit Trail" in the navigation menu
    And I click "View" in the first "Study" row
    Then I see a row with "This is a comment"

  # TODO: Discuss Scenario: Scoped permission to study
  # TODO: Discuss Scenario: Scoped permission to center
  # TODO: Discuss Scenario: Scoped permission to patient
