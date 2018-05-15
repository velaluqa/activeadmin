Feature: Update Study
  In order to adjust study details,
  As authorized user to update study,
  I can update a study.

  Background:
    Given a study "FooStudy"
    And a role "Image Manager" with permissions:
      | Study | read, update |

  Scenario: Not logged in
    When I browse to edit study "FooStudy"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot update studies
    When I browse to studies list
    Then I don't see "ViewEditDelete"
    And I see "ViewDelete"
    When I browse to study "FooStudy"
    Then I don't see "Edit Study"
    When I browse to edit study "FooStudy"
    Then I see the unauthorized page

  Scenario: Change Name
    Given I sign in as a user with role "Image Manager"
    When I browse to study "FooStudy"
    And I follow link "Edit Study"
    Then I see "Edit Study"
    When I fill in "Updated Study" for "Name*"
    And I click the "Update Study" button
    Then I am redirected to study "Updated Study"
    And I see "Name Updated Study"
    And I see "Study was successfully updated"

  # TODO: Discuss Scenario: Scoped-permission to Study
  # TODO: Discuss Scenario: Scoped-permission to Center
  # TODO: Discuss Scenario: Scoped-permission to Patient
