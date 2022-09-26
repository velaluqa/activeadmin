Feature: Update Visit Tags
  In order to manage tags of a visit,
  As authorized user for `update_tags` for visit,
  I can add and remove tags for a visit.

  Background:
    Given a visit "10000" with:
      | tags | my_tag |  
    And a visit "20000" with:
      | tags | other_tag |  
    And a role "Authorized Role" with permissions:
      | Visit | read, read_tags, update_tags |
    And a role "Unauthorized Role" with permissions:
      | Visit | read, read_tags |

  Scenario: Authorized to update tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to visits page
    Then I see "my_tag" in "10000" row
    But I don't see "other_tag" in "10000" row
    When I click the pencil icon in "10000" row
    When I search "ot" for "Tags" and select "other_tag" 
    And I click "Submit" 
    Then I see "my_tag" in "10000" row
    And I see "other_tag" in "10000" row

  Scenario: Unauthorized to update tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to visits page
    Then I see "my_tag" in "10000" row
    And I see "other_tag" in "20000" row
    But I don't see the edit pencil icon in "10000" row
    And I don't see the edit pencil icon in "20000" row
    
