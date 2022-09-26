Feature: Update Patient Tags
  In order to manage tags of a patient,
  As authorized user for `update_tags` for patient,
  I can add and remove tags for a patient.

  Background:
    Given a patient "First Patient" with:
      | tags | my_tag |  
    And a patient "Second Patient" with:
      | tags | other_tag |  
    And a role "Authorized Role" with permissions:
      | Patient | read, read_tags, update_tags |
    And a role "Unauthorized Role" with permissions:
      | Patient | read, read_tags |

  Scenario: Authorized to update tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to patients page
    Then I see "my_tag" in "First Patient" row
    But I don't see "other_tag" in "First Patient" row
    When I click the pencil icon in "First Patient" row
    When I search "other_tag" for "Tags" and select "other_tag" 
    And I click "Submit" 
    Then I see "my_tag" in "First Patient" row
    And I see "other_tag" in "First Patient" row

  Scenario: Unauthorized to update tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to patients page
    Then I see "my_tag" in "First Patient" row
    And I see "other_tag" in "Second Patient" row
    But I don't see the edit pencil icon in "First Patient" row
    And I don't see the edit pencil icon in "Second Patient" row
    