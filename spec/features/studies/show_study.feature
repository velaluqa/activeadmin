Feature: Show Visit
  In order to perform image management,
  As authorized user for read study,
  I want to see all study details in a table view.

  Background:
    Given a study "FooStudy"
    And a role "Image Manager" with permissions:
      | Study | read |

  Scenario: Not logged in
    When I browse to study "FooStudy"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot read studies
    When I browse to study "FooStudy"
    Then I see the unauthorized page

  Scenario: Success
    Given I sign in as a user with role "Image Manager"
    When I browse to study "FooStudy"
    Then I see "Name FooStudy"
    Then I see "Domino Db Url DOMINO INTEGRATION NOT ENABLED"
    Then I see "Domino Server Name Empty"
    Then I see "State Building"

  # TODO: Discuss Scenario: Scoped permission to study
  # TODO: Discuss Scenario: Scoped permission to center
  # TODO: Discuss Scenario: Scoped permission to patient
