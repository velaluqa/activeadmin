Feature: Choose displayed columns
  In order to reduce the amount of unnecessary cluttering info,
  As authorized user,
  I want to choose the columns that are displayed to me.

  Background:
      Given a study "TestStudy"
    And a center "TestCenter" for "TestStudy"
    And a patient "TestPatient" for "TestCenter"
    And a visit "1000" for "TestPatient"
    And a image_series "TestSeries" for "TestPatient"
    And an image for image series "TestSeries"
    And a role "Image Manager" with permissions:
      | Patient | read, comment |

  Scenario: Successfully change columns of study list
    Given I sign in as a user with all permissions
    When I browse to patient list
    Then I see the following columns:
      | Center | Subject | Tags | 
    Then I click link "View Columns"
    Then I click button "Clear Selected"
    And I check "tags"
    When I click button "Submit"
    Then I don't see the following columns:
     | Center | Subject |
    And I see a column "Tags"
    Then I click link "View Columns"
    And I uncheck "tags"
    When I click button "Submit"
    Then I see the following columns:
    | Center | Subject | Tags | 