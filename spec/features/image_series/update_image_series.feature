Feature: Update Image Series
  In order to update an image series,
  As authorized user for `edit` image series,
  I want to be able to update a particular image series entry.

  Background:
    Given a study "FooStudy"
    And a center "FooCenter" for "FooStudy"
    And a patient "FooPatient" for "FooCenter"
    And a visit "10000" with:
      | patient     | FooPatient           |
      | visit_type  | followup             |
      | description | Visit Extraordinaire |
    And an image_series "TestSeries" with:
      | patient | FooPatient       |
      | visit   | 10000            |
    
  Scenario: Unauthorized to update image series
    When I sign in as a user with all permissions
    But I cannot update image_series
    When I browse to image_series list
    Then I don't see "Edit" in "TestSeries" row

  Scenario: Update image series name
    When I sign in as a user with all permissions
    And I browse to image_series list
    And I click "Edit" in "TestSeries" row
    Then I see "DETAILS"
    When I fill in "Name" with "New Image Name"
    And I click the "Update Image series" button
    Then I see "Image series was successfully updated."
    And I see "New Image Name" in "Name" row
  
  Scenario: Update image series number
    When I sign in as a user with all permissions
    And I browse to image_series list
    And I click "Edit" in "TestSeries" row
    Then I see "DETAILS"
    When I fill in number field "Series number" with 5
    And I click the "Update Image series" button
    Then I see "Image series was successfully updated."
