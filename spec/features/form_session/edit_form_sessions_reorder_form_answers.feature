Feature: Reorder form answers
  In order to specify the order in which a user can answer the necessary forms,
  As authorized user for edit FormSession,
  I can reorder the form answers via drag and drop on the edit form answer page.

  Background:
    Given a role "Authorized" with permissions:
      | FormSession     | read, update |
      | FormDefinition  | read         |
      | FormAnswer      | read         |
    And a role "Unauthorized" with permissions:
      | FormSession     | read         |
      | FormDefinition  | read         |
      | FormAnswer      | read         |
    And a user "authorized.user" with role "Authorized"
    And a user "unauthorized.user" with role "Unauthorized"
    And a study "FooStudy"
    And a center "FooCenter" with:
      | study | FooStudy |
      | code  |       00 |
    And a patient "1stPatient" for "FooCenter"
    And a patient "2ndPatient" for "FooCenter"
    And form definition "TestForm" with:
      | validates_resource_id | required |
    And form session "TestSession"
    And "TestForm" form data with:
      | form_session    | TestSession        |
      | resource        | Patient 1stPatient |
      | sequence_number | 2                  |
    And "TestForm" form data with:
      | form_session    | TestSession        |
      | resource        | Patient 2ndPatient |
      | sequence_number | 1                  |

  Scenario: Unauthorized
    When I sign in as user "unauthorized.user"
    And I browse to form_sessions list
    And I click "View" in "TestSession" row
    Then I don't see "Edit Form Session"

  Scenario: Successfully reorder form answers
    When I sign in as user "authorized.user"
    And I browse to form_sessions list
    And I click "View" in "TestSession" row
    Then I see in given order:
      | 2ndPatient |
      | 1stPatient |
    Then I see "Edit Form Session"
    When I click "Edit Form Session"
    Then I see in given order:
     | TestForm      |
     | 002ndPatient  |
     | draft         |
     | Not published |
     | Not submitted |
    And I see in given order:
     | TestForm      |
     | 001stPatient  |
     | draft         |
     | Not published |
     | Not submitted |
   When I drag the draggable of "001stPatient" onto the draggable of "002ndPatient"
   And I click "Update Form session"
   Then I see "Form session was successfully updated"
   And I see in given order:
     | 1stPatient |
     | 2ndPatient |

    
