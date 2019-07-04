Feature: Create Study
  In order to perform image managment and quality control,
  As authorized user for study creation,
  I can create studies.

  Background:
    Given a role "Image Manager" with permissions:
      | Study   | read, create         |

  Scenario: Not logged in
    When I browse to new study form
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot create study
    When I browse to studies list
    Then I don't see "New Study"
    When I browse to new study form
    Then I see the unauthorized page

  Scenario: Image Manager Role System-Wide
    Given I sign in as a user with role "Image Manager"
    When I browse to studies list
    Then I see "New Study"
    When I click link "New Study"
    Then I see "New Study"
    And I fill in "Name*" with "Newly Created Study"
    And I click the "Create Study" button
    Then I am redirected to study "Newly Created Study"
    And I see "Study was successfully created"
