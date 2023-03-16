Feature: Destroy Form Definitions
  In order to remove a form definitions,
  As authorized user for `destroy FormDefinition`,
  I can destroy a form definition.

  Scenario: Unauthorized
    Given form definition "TestForm"
    When I sign in as a user with all permissions
    But I cannot destroy form_definitions
    When I browse to form_definitions list
    Then I don't see a "Delete" link in row for "TestForm"
    When I click "View" in "TestForm" row
    Then I don't see "Delete Form Definition"

  Scenario: Delete from index page saves comment for audittrail
    Given a role "Authorized" with permissions:
      | FormDefinition     | read, destroy |
      | Version            | read          |
    And form definition "TestForm"
    And a user "authorized.user" with role "Authorized"
    When I sign in as user "authorized.user"
    And I browse to form_definitions list
    And I click "Delete" in "TestForm" row
    And I provide "This is a comment" for browser prompt and confirm
    And I browse to form_definitions list
    Then I don't see a row with "TestForm"
    When I click "Audit Trail" in the navigation menu
    And I click "View" in the first "FormDefinition" row
    Then I see a row with "This is a comment"

  Scenario: Delete from show page saves comment for audittrail
    Given a role "Authorized" with permissions:
      | FormDefinition     | read, destroy |
      | Version            | read          |
    And form definition "TestForm"
    And a user "authorized.user" with role "Authorized"
    When I sign in as user "authorized.user"
    And I browse to form_definitions list
    And I click "View" in "TestForm" row
    And I click link "Delete Form Definition"
    And I provide "This is a comment" for browser prompt and confirm
    And I browse to form_definitions list
    Then I don't see a row with "TestForm"
    When I click "Audit Trail" in the navigation menu
    And I click "View" in the first "FormDefinition" row
    Then I see a row with "This is a comment"