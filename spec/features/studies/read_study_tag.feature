Feature: Read studies by tags
  As authorized user for `read_tags` for study,
  I can see the tags for the studies.

  Background:
    Given a study "First Study" with:
      | tags | my_tag, other_tag |  
    And a study "Second Study" with:
      | tags | other_studies_tag |  
    And a role "Authorized Role" with permissions:
      | Study | read, read_tags |
    And a role "Unauthorized Role" with permissions:
      | Study | read |

  Scenario: Authorized to read study tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to studies list
    Then I see "my_tag" in "First Study" row
    And I see "other_studies_tag" in "Second Study" row
    When I click "View" in "First Study" row
    Then I see "my_tag" in "Tags" row 
    And I see "other_tag" in "Tags" row

  Scenario: Unauthorized to read study tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to studies list
    Then I don't see "my_tag" in "First Study" row
    And I don't see "other_studies_tag" in "Second Study" row
    
