Feature: Choose displayed columns
  In order to reduce the amount of unnecessary cluttering info,
  As authorized user,
  I want to choose the columns that are displayed to me.  
  
  Background:
    Given a study "First Study" with:
      | tags | my_tag, other_tag |  
    And a study "Second Study" with:
      | tags | other_studies_tag |  
    And a role "Authorized Role" with permissions:
      | Study | read, read_tags |
    And a role "Unauthorized Role" with permissions:
      | Study | read |

  Scenario: Successfully change columns of studies table
    Given I sign in as a user with all permissions
    And I browse to studies page
    Then I see the following columns:
      | Name | Configuration | State | Select For Session | Tags |
    Then I click link "View Columns"
    
    Then I click button "Clear Selected"
    And I check "state"
    When I click button "Submit"
    Then I don't see the following columns:
      | Name | Configuration | Select For Session | Tags |
    And I see a column "State"
    Then I click link "View Columns"
    And I uncheck "state"
    When I click button "Submit"
    Then I see the following columns:
      | Name | Configuration | State | Select For Session | Tags |