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
      | patient | FooPatient |
    And a role "Image Manager" with permissions:
      | Study       | read                          |
      | Visit       | read                          |
      | Center      | read                          |
      | Patient     | read                          |
      | ImageSeries | read, update                  |
  
  Scenario: Update success for an image series entry
    When I sign in as a user with role "Image Manager"
    Then I browse to image_series list
    And I see "Edit" in "TestSeries" row
    When I click "Edit" in "TestSeries" row
    Then I see "DETAILS"
    When I select "FooPatient#10000" from "Visit"
    And I click the "Update Image series" button
    Then I see "Image series was successfully updated."
    And I see "FooPatient#10000" in "Visit" row
