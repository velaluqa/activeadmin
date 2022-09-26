Feature: Update Center Tags
  In order to manage tags of a center,
  As authorized user for `update_tags` for center,
  I can add and remove tags for a center.

  Background:
    Given a center "First Center" with:
      | tags | my_tag |  
    And a center "Second Center" with:
      | tags | other_tag |  
    And a role "Authorized Role" with permissions:
      | Center | read, read_tags, update_tags |
    And a role "Unauthorized Role" with permissions:
      | Center | read, read_tags |

  Scenario: Authorized to update tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to centers page
    Then I see "my_tag" in "First Center" row
    But I don't see "other_tag" in "First Center" row
    When I click the pencil icon in "First Center" row
    When I search "other_tag" for "Tags" and select "other_tag" 
    And I click "Submit" 
    Then I see "my_tag" in "First Center" row
    And I see "other_tag" in "First Center" row

  Scenario: Unauthorized to update tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to centers page
    Then I see "my_tag" in "First Center" row
    And I see "other_tag" in "Second Center" row
    But I don't see the edit pencil icon in "First Center" row
    And I don't see the edit pencil icon in "Second Center" row
    