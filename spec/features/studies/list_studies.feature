Feature: List Studies
  In order to perform image management or quality control,
  As authorized user to list studies,
  I want to see a list of all studies.

  Background:
    Given a study "FooStudy"
    And a study "BarStudy"
    And a role "Image Manager" with permissions:
      | Study | read |

  Scenario: Not logged in
    When I browse to studies list
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot read studies
    When I browse to studies list
    Then I see the unauthorized page

  Scenario: All studies
    Given I sign in as a user with role "Image Manager"
    When I browse to studies list
    Then I see "FooStudy MISSING Building"
    And I see "BarStudy MISSING Building"

  Scenario: `FooStudy` selected for session
    Given I sign in as a user with role "Image Manager"
    When I browse to study "FooStudy"
    And I click link "Select"
    And I browse to studies list
    Then I see "FooStudy MISSING Building"
    And I see "BarStudy MISSING Building"

  Scenario: Scoped Permission to `FooStudy`
    Given I sign in as a user with role "Image Manager" scoped to study "FooStudy"
    When I browse to studies list
    Then I see "FooStudy MISSING Building"
    But I don't see "BarStudy MISSING Building"
    
  # TODO: Discuss Scenario: Scoped permission to center
  # TODO: Discuss Scenario: Scoped permission to patient
