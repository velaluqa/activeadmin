Feature: Destroy Form Answers
  In order to remove a form answers,
  As authorized user for `destroy FormAnswer`,
  I can destroy a form answer.

  Notes:

  - Signed form answer MUST NOT be deleted
  
  Scenario: Cannot destroy signed form answers
    Given a role "Authorized" with permissions:
      | FormAnswer  | read, destroy |
    Given a user "authorized.user" with role "Authorized"
    Given form definition "TestForm"
    And a form answer for "TestForm" signed by user "authorized.user" with data:
      | textField | My Text Value   |
      | textArea  | Some other text |
      | number    | 15              |
    When I sign in as user "authorized.user"
    And I browse to form_answers list
    And I click "View" in "TestForm" row
    And I click link "Delete Form Answer" and confirm
    Then I see "Cannot delete signed form answers"
    When I browse to form_answers list
    Then I see "SIGNED" in "TestForm" row

  Scenario: Allows deletion of unsigned form answers
    Given a role "Authorized" with permissions:
      | FormAnswer | read, destroy |
      | Version    | read          |
    And a user "authorized.user" with role "Authorized"
    And form definition "TestForm"
    And a form answer for "TestForm" with data:
      | textField | My Text Value   |
      | textArea  | Some other text |
      | number    | 15              |
    When I sign in as user "authorized.user"
    And I browse to form_answers list
    Then I see "DRAFT" in "TestForm" row
    When I click "Delete" in "TestForm" row
    And I dismiss popup
    Then I see a row with "TestForm"
    When I click link "Delete"
    And I provide "This is a comment" for browser prompt and confirm
    And I browse to form_answers list
    Then I don't see a row with "TestForm"
    When I click "Audit Trail" in the navigation menu
    And I click "View" in the first "FormAnswer" row
    Then I see "This is a comment" in "Comment" row    
