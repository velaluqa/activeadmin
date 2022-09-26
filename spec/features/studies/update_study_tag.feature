Feature: Update Study Tags
  In order to manage tags of a study,
  As authorized user for `update_tags` for study,
  I can add and remove tags for a study.

  Background:
    Given a study "First Study" with:
      | tags | my_tag |  
    And a study "Second Study" with:
      | tags | other_tag |  
    And a role "Authorized Role" with permissions:
      | Study | read, read_tags, update_tags |
    And a role "Unauthorized Role" with permissions:
      | Study | read, read_tags |

  Scenario: Authorized to update tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to studies page
    Then I see "my_tag" in "First Study" row
    But I don't see "other_tag" in "First Study" row
    When I click the pencil icon in "First Study" row
    When I search "other_tag" for "Tags" and select "other_tag" 
    And I click "Submit" 
    Then I see "my_tag" in "First Study" row
    And I see "other_tag" in "First Study" row

  Scenario: Unauthorized to update tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to studies page
    Then I see "my_tag" in "First Study" row
    And I see "other_tag" in "Second Study" row
    But I don't see the edit pencil icon in "First Study" row
    And I don't see the edit pencil icon in "Second Study" row
    