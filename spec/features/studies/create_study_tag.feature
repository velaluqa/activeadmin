Feature: Create Simple Study Tags
  In order to mark studies on the fly with new tags while managing studies,
  As authorized user for `create_tags` Study,
  I want to create tags from the select box when updating tags.

  Background:
    Given a study "Test Study"
    And a role "Authorized Role" with permissions:
      | Study | read, read_tags, update_tags, create_tags |
    And a role "Unauthorized Role" with permissions:
      | Study | read, read_tags |

  Scenario: Authorized to create tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to study "Test Study" 
    Then I see "Add Tags" 
    When I click "Add Tags" 
    Then I see "Tags" 
    When I search "newtag" for "Tags" and select "newtag" 
    And I click "Submit" 
    Then I see "newtag" in "Tags" row

  Scenario: Unauthorized to create tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to study "Test Study" 
    Then I don't see "Add Tags" 
    