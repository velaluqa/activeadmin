Feature: Read centers by tags
  As authorized user for `read_tags` for center,
  I can see the tags for the centers.

  Background:
    Given a center "First Center" with:
      | tags | my_tag, other_tag |  
    And a center "Second Center" with:
      | tags | other_centers_tag |  
    And a role "Authorized Role" with permissions:
      | Center | read, read_tags |
    And a role "Unauthorized Role" with permissions:
      | Center | read |

  Scenario: Authorized to read center tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to centers list
    Then I see "my_tag" in "First Center" row
    And I see "other_centers_tag" in "Second Center" row
    When I click "View" in "First Center" row
    Then I see "my_tag" in "Tags" row 
    And I see "other_tag" in "Tags" row

  Scenario: Unauthorized to read center tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to centers list
    Then I don't see "my_tag" in "First Center" row
    And I don't see "other_centers_tag" in "Second Center" row
    
