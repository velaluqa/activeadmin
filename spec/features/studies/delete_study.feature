Feature: Delete Study
  In order to remove studies that are false or obsolete,
  As authorized user for deletion of studies,
  I can delete a study.

  Background:
    Given a study "FooStudy"
    And a role "Image Manager" with permissions:
      | Study   | read, destroy        |

  Scenario: Not logged in
    When I browse to studies list
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot destroy studies
    When I browse to studies list
    Then I don't see "FooStudy MISSING Building Select ViewDelete"
    When I browse to study "FooStudy"
    Then I don't see "Delete Study"

  Scenario: Successful
    Given I sign in as a user with role "Image Manager"
    When I browse to studies list
    Then I see "FooStudy MISSING Building Select ViewDelete"
    When I follow link "Delete"
    Then I don't see "FooStudy MISSING Building"

  # TODO: Discuss Scenario: Scoped permission to study
  # TODO: Discuss Scenario: Scoped permission to center
  # TODO: Discuss Scenario: Scoped permission to patient
