Feature: Filter centers by tags
  In order to filter according to configurable labels (i.e. Tags)
  As authorized user for `read_tags` for center,
  I can filter for certain tags in the system.

  Background:
    Given a center "First Center" with:
      | tags | my_tag, other_tag |  
    And a center "Second Center" with:
      | tags | other_centers_tag |  
    And a role "Authorized Role" with permissions:
      | Center | read, read_tags |
    And a role "Unauthorized Role" with permissions:
      | Center | read |
 
  Scenario: Authorized to filter centers by tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to centers page
    Then I see "my_tag" in "First Center" row
    And I see "other_centers_tag" in "Second Center" row
    When I click link "View Filters"
    And I select "my_tag" for "Tags"
    And I click "Filter"
    Then I see "First Center"
    But I don't see "Second Center"

  Scenario: Unauthorized to filter centers by tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to centers page
    Then I don't see "Tags"
    
