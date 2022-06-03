Feature: Edit Form Answers
  In order to update form answers,
  As authorized user for `update FormAnswer`,
  I can edit and update a form answer.

  Notes:

  - Signed form answer MUST NOT be edited
  
  Scenario: Cannot edit signed form answers
    Given a role "Authorized" with permissions:
      | FormAnswer  | read, update |
    Given a user "authorized.user" with role "Authorized"
    Given form definition "TestForm"
    And a form answer for "TestForm" signed by user "authorized.user" with data:
      | textField | My Text Value   |
      | textArea  | Some other text |
      | number    | 15              |
    When I sign in as user "authorized.user"
    And I browse to form_answers list
    And I click "Edit" in "TestForm" row
    Then I see "Cannot update signed form answers"

  Scenario: Allows update of unsigned form answers
    Given a role "Authorized" with permissions:
      | FormAnswer | read, update |
    And a user "authorized.user" with role "Authorized"
    And form definition "TestForm"
    And a form answer for "TestForm" with data:
      | textField | My Text Value   |
      | textArea  | Some other text |
      | number    | 15              |
    When I sign in as user "authorized.user"
    And I browse to form_answers list
    And I click "Edit" in "TestForm" row
    Then I see field "Text Field" with value "My Text Value"
    When I fill in "Text Field" with "Some Brand New Value"
    Then I see field "Text Field" with value "Some Brand New Value"
    When I click "Update Form answer"
    Then I see "Form answer was successfully updated"
    When I click "Raw"
    Then I see "Some Brand New Value"
    
    

