Feature: Upload Form Layout from Form Definition JSON
  In order transfer existing form definitions to the system,
  As authorized user for `update form definition`,
  I can upload a form definition configuration json to the form layout editor.

  Background:
    Given a role "Authorized" with permissions:
      | FormDefinition | create, read, update, destroy |
    And a form definition "Test Form"

  Scenario: Upload form definition configuration
    When I sign in as a user with role "Authorized"
    And I browse to form_definition list
    And I click "View" in "Test Form" row
    And I click "Form Layout Editor"
    And I provide file "test_form.json" for "Upload JSON" 
    Then I see a form with:
      | Text Field |
      | Text Area  |
      | Number     |

  
  

    
