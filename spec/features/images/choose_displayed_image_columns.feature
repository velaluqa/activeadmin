Feature: Choose displayed columns
  In order to reduce the amount of unnecessary cluttering info,
  As authorized user,
  I want to choose the columns that are displayed to me.

  Background:
    Given an image_series "IS"
    And a DICOM image for image series "IS"

  Scenario: Successfully change columns of image page
    Given I sign in as a user with all permissions
    And I browse to image_series list
    And I click "1 file" in "IS" row 
    Then I see the following columns:
    | Image Series | Id | Type | Status | View |
    Then I click link "View Columns"
    Then I click button "Clear Selected"
    And I check "id"
    When I click button "Submit"
    Then I don't see the following columns:
     | Image Series | Type | Status | View |
    And I see the following columns:
        | Id |
    Then I click link "View Columns"
    And I uncheck "id"
    When I click button "Submit"
    Then I see the following columns:
    | Image Series | Id | Type | Status | View |