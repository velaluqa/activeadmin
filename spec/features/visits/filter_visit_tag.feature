Feature: Filter visits by tags
  In order to filter according to configurable labels (i.e. Tags)
  As authorized user for `read_tags` for visit,
  I can filter for certain tags in the system.

  Background:
    Given a visit "10000" with:
      | tags | my_tag, other_tag |  
    And a visit "20000" with:
      | tags | other_visits_tag |  
    And a role "Authorized Role" with permissions:
      | Visit | read, read_tags |
    And a role "Unauthorized Role" with permissions:
      | Visit | read |


  Scenario: Authorized to filter visits by tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to visits page
    Then I see "my_tag" in "10000" row
    And I see "other_visits_tag" in "20000" row
    When I select "my_tag" for "Tags"
    And I click "Filter"
    Then I see "10000"
    But I don't see "20000"

  Scenario: Unauthorized to filter visits by tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to visits page
    Then I don't see "Tags"
  
