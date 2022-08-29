Feature: Update User Tags
  In order to manage tags of a user,
  As authorized user for `update_tags` for user,
  I can add and remove tags for a user.

  Background:
    Given a user "Alex" with:
      | tags | my_tag |  
    And a user "John" with:
      | tags | other_tag |  
    And a role "Authorized Role" with permissions:
      | User | read, read_tags, update_tags |
    And a role "Unauthorized Role" with permissions:
      | User | read, read_tags |

  Scenario: Authorized to update tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to users list
    Then I see "my_tag" in "Alex" row
    But I don't see "other_tag" in "Alex" row
    When I click the pencil icon in "Alex" row
    When I search "other_tag" for "Tags" and select "other_tag" 
    And I click "Submit" 
    Then I see "my_tag" in "Alex" row
    And I see "other_tag" in "Alex" row

  Scenario: Unauthorized to update tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to users list
    Then I see "my_tag" in "Alex" row
    And I see "other_tag" in "John" row
    But I don't see the edit pencil icon in "Alex" row
    And I don't see the edit pencil icon in "John" row
    