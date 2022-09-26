Feature: Create Simple Center Tags
  In order to mark centers on the fly with new tags while managing centers,
  As authorized user for `create_tags` Center,
  I want to create tags from the select box when updating tags.

  Background:
    Given a center "Test Center"
    And a role "Authorized Role" with permissions:
      | Center | read, read_tags, update_tags, create_tags |
    And a role "Unauthorized Role" with permissions:
      | Center | read, read_tags |

  Scenario: Authorized to create tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to center "Test Center" 
    Then I see "Add Tags" 
    When I click "Add Tags" 
    Then I see "Tags" 
    When I search "newtag" for "Tags" and select "newtag" 
    And I click "Submit" 
    Then I see "newtag" in "Tags" row

  Scenario: Unauthorized to create tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to center "Test Center" 
    Then I don't see "Add Tags" 
    