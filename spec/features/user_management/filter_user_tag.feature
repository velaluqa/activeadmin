Feature: Filter users by tags
  In order to filter according to configurable labels (i.e. Tags)
  As authorized user for `read_tags` for user,
  I can filter for certain tags in the system.

  Background:
    Given a user "Alex" with:
      | tags | my_tag, other_tag |  
    And a user "John" with:
      | tags | other_users_tag |  
    And a role "Authorized Role" with permissions:
      | User | read, read_tags |
    And a role "Unauthorized Role" with permissions:
      | User | read |

  Scenario: Authorized to filter users by tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to users list
    Then I see "my_tag" in "Alex" row
    And I see "other_users_tag" in "John" row
    Then I click link "View Filters"
    When I select "my_tag" for "Tags"
    And I click "Filter"
    Then I see "Alex"
    But I don't see "John"

  Scenario: Unauthorized to filter users by tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to users list
    Then I don't see "Tags"
    
