Feature: Read visits by tags
  As authorized user for `read_tags` for visit,
  I can see the tags for the visits.

  Background:
    Given a visit "10000" with:
      | tags | my_tag, other_tag |  
    And a visit "20000" with:
      | tags | other_visits_tag |  
    And a role "Authorized Role" with permissions:
      | Visit | read, read_tags |
    And a role "Unauthorized Role" with permissions:
      | Visit | read |

  Scenario: Authorized to read visit tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to visits list
    Then I see "my_tag" in "10000" row
    And I see "other_visits_tag" in "20000" row
    When I click "View" in "10000" row
    Then I see "my_tag" in "Tags" row 
    And I see "other_tag" in "Tags" row

  Scenario: Unauthorized to read visit tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to visits list
    Then I don't see "my_tag" in "10000" row
    And I don't see "other_visits_tag" in "20000" row
  