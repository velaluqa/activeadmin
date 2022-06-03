Feature: Destroy Form Session
  In order to remove a form session that is not needed anymore,
  As authorized user for `destroy FormSession`,
  I can destroy a form session.

  Notes:

  - Sessions with signed form answers cannot be destroyed
  
  Scenario: Cannot destroy form session with form answers
    Given a role "Authorized" with permissions:
      | FormSession    | read, destroy |
    Given a user "authorized.user" with role "Authorized"
    Given form definition "TestForm" with:
      | validates_form_session_id | required |
    And form session "TestSession"
    And "TestForm" form data with:
      | form_session | TestSession |
    When I sign in as user "authorized.user"
    And I browse to form_sessions list
    And I click "View" in "TestSession" row
    Then I see "1 TestForm DRAFT"
    And I click link "Delete Form Session" and confirm
    Then I see "Cannot delete session with associated form data."
    
  Scenario: Allows deletion of empty form session
    Given a role "Authorized" with permissions:
      | FormSession    | read, destroy |
    Given a user "authorized.user" with role "Authorized"
    Given form definition "TestForm" with:
      | validates_form_session_id | required |
    And form session "TestSession"
    When I sign in as user "authorized.user"
    And I browse to form_sessions list
    And I click "View" in "TestSession" row
    And I click link "Delete Form Session" and confirm
    Then I see "Form session was successfully destroyed"
    
