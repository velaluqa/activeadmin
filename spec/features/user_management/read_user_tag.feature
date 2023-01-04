Feature: Read users by tags
  As authorized user for `read_tags` for user,
  I can see the tags for the users.

  Background:
    Given a user "Alex Mueller" with:
      | tags | my_tag, other_tag |  
    And a user "John Maier" with:
      | tags | other_users_tag |  
    And a role "Authorized Role" with permissions:
      | User | read, read_tags |
    And a role "Unauthorized Role" with permissions:
      | User | read |

  Scenario: Authorized to read user tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to users list
    Then I see "my_tag" in "Alex Mueller" row
    And I see "other_users_tag" in "John Maier" row
    When I click "View" in "Alex Mueller" row
    Then I see "my_tag" in "Tags" row 
    And I see "other_tag" in "Tags" row

  Scenario: Unauthorized to read user tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to users list
    Then I don't see "my_tag" in "Alex Mueller" row
    And I don't see "other_users_tag" in "John Maier" row
    
