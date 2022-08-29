Feature: Read patients by tags
  As authorized user for `read_tags` for patient,
  I can see the tags for the patients.

  Background:
    Given a patient "First Patient" with:
      | tags | my_tag, other_tag |  
    And a patient "Second Patient" with:
      | tags | other_patients_tag |  
    And a role "Authorized Role" with permissions:
      | Patient | read, read_tags |
    And a role "Unauthorized Role" with permissions:
      | Patient | read |

  Scenario: Authorized to read patient tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to patients list
    Then I see "my_tag" in "First Patient" row
    And I see "other_patients_tag" in "Second Patient" row
    When I click "View" in "First Patient" row
    Then I see "my_tag" in "Tags" row 
    And I see "other_tag" in "Tags" row

  Scenario: Unauthorized to read patient tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to patients list
    Then I don't see "my_tag" in "First Patient" row
    And I don't see "other_patients_tag" in "Second Patient" row
    
