Feature: Assign Newly Created Visit
  In order to simplify image management for quality control,
  As authorized user that can assign image series to visits and create visits,
  I can create a new visit in the assign visit form.

  Background:
    Given a study "FooStudy" with configuration
      """
      visit_types:
        baseline: 
          required_series: {}
        followup: 
          required_series:
            SPECT_1:
              tqc: []
            SPECT_2:
              tqc: []
      image_series_properties: []
      """
    And a center "FooCenter" for "FooStudy"
    And a patient "FooPatient" for "FooCenter"
    And a visit "10000" with:
      | patient     | FooPatient           |
      | visit_type  | followup             |
      | description | Visit Extraordinaire |
    And an image_series "TestSeries" with:
      | patient | FooPatient |
    And a role "Image Manager" with permissions:
      | Study       | read                 |
      | Center      | read, update         |
      | Patient     | read, update, create |
      | Visit       | read, update, create |
      | ImageSeries | read, assign_visit   |

  Scenario: Not logged in
    When I browse to assign_visit_form image_series "TestSeries"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized to assign visits
    Given I sign in as a user with all permissions
    But I cannot assign_visit image_series
    When I browse to image_series list
    Then I don't see "Assign Visit"
    When I browse to assign_visit_form image_series "TestSeries"
    Then I see the unauthorized page

  Scenario: Unauthorized to create visits
    Given I sign in as a user with all permissions
    But I cannot create visits
    When I browse to image_series list
    And I click link "Assign Visit"
    Then I see "ASSIGN VISIT"
    And I don't see "WHEN CREATING A NEW VISIT"

  Scenario: Assignment of Newly Created Visit Successful 
    Given I sign in as a user with role "Image Manager"
    When I browse to image_series list
    Then I see "Assign Visit"
    When I click link "Assign Visit"
    Then I see "ASSIGN VISIT"
    And I see "WHEN CREATING A NEW VISIT"
    When I select "Create New Visit" from "Visit"
    And I fill in "Visit number" with "20000"
    And I select "followup" from "Visit type"
    And I fill in "Description" with "Newly created visit"
    And I click the "Assign Visit" button
    Then I am redirected to image_series list
    And I see "#20000"
