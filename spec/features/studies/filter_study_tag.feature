Feature: Filter studies by tags
  In order to filter according to configurable labels (i.e. Tags)
  As authorized user for `read_tags` for study,
  I can filter for certain tags in the system.

  Background:
    Given a study "First Study" with:
      | tags | my_tag, other_tag |  
    And a study "Second Study" with:
      | tags | other_studies_tag |  
    And a role "Authorized Role" with permissions:
      | Study | read, read_tags |
    And a role "Unauthorized Role" with permissions:
      | Study | read |
      
  Scenario: Authorized to filter studies by tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to studies page
    Then I see "my_tag" in "First Study" row
    And I see "other_studies_tag" in "Second Study" row
    Then I click link "View Filters"
    When I select "my_tag" for "Tags"
    And I click "Filter"
    Then I see "First Study"
    But I don't see "Second Study"

  Scenario: Unauthorized to filter stuides by tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to studies page
    Then I don't see "Tags"
    
