Feature: Filter patients by tags
  In order to filter according to configurable labels (i.e. Tags)
  As authorized user for `read_tags` for patient,
  I can filter for certain tags in the system.

  Background:
    Given a patient "First Patient" with:
      | tags | my_tag, other_tag |  
    And a patient "Second Patient" with:
      | tags | other_patients_tag |  
    And a role "Authorized Role" with permissions:
      | Patient | read, read_tags |
    And a role "Unauthorized Role" with permissions:
      | Patient | read |
      
  Scenario: Authorized to filter patients by tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to patients page
    Then I see "my_tag" in "First Patient" row
    And I see "other_patients_tag" in "Second Patient" row
    Then I click link "View Filters"
    When I select "my_tag" for "Tags"
    And I click "Filter"
    Then I see "First Patient"
    But I don't see "Second Patient"

  Scenario: Unauthorized to filter patients by tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to patients page
    Then I don't see "Tags"
    
