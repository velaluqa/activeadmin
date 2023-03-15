Feature: Choose displayed columns
  In order to reduce the amount of unnecessary cluttering info,
  As authorized user,
  I want to choose the columns that are displayed to me.

  Background:
    Given a study "FooStudy"
    And a center "FooCenter" for "FooStudy"
    And a patient "FooPatient" for "FooCenter"
    And a visit "10000" for "FooPatient"
    And an image_series "FooImageSeries" with:
      | patient     | FooPatient |
      | visit       |      10000 |
      | image_count |          1 |
  
  Scenario: Successfully change columns of image_series list
    Given I sign in as a user with all permissions
    When I browse to image_series list
    Then I see the following columns:
      | Id | Study Name | Patient | Visit | Series Number | Name | Imaging Date | Import Date | Files | Image Types | State | comment | tags | View In |
    Then I click link "View Columns"
    Then I click button "Clear Selected"
    And I check "state"
    When I click button "Submit"
    Then I don't see the following columns:
      | Id | Study Name | Patient | Visit | Series Number | Name | Imaging Date | Import Date | Files | Image Types | comment | tags | View In |
    And I see a column "State"
    Then I click link "View Columns"
    And I uncheck "state"
    When I click button "Submit"
    Then I see the following columns:
         | Id | Study Name | Patient | Visit | Series Number | Name | Imaging Date | Import Date | Files | Image Types | State | comment | tags | View In |



