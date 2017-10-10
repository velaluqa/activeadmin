Feature: Assign Required Series
  In order to mark an image series for quality control,
  As authorized user that can assign required series,
  I can assign an image series to a visits required series.

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
    And an image_series "TestSeries1" with:
      | patient | FooPatient     |
      | visit   | 10000          |
      | state   | visit_assigned |
    And an image_series "TestSeries2" with:
      | patient | FooPatient |
      | state   | imported   |
    And a role "Image Manager" with permissions:
      | Study       | read                         |
      | Center      | read, update                 |
      | Patient     | read, update, create         |
      | ImageSeries | read                         |
      | Visit       | read, assign_required_series |

  Scenario: Not logged in
    When I browse to assign_required_series_form image_series "TestSeries1"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user
    And I can read image_series
    And I cannot assign_required_series visits
    When I browse to visits list
    And I don't see "Assign RS" in "TestSeries1" row
    And I don't see "Assign RS" in "TestSeries2" row
    When I browse to assign_required_series_form image_series "TestSeries1"
    Then I see the unauthorized page

  Scenario: No Visit Assigned
    Given I sign in as a user with role "Image Manager"
    When I browse to image_series list
    Then I don't see "Assign RS" in "TestSeries2" row
    When I browse to assign_required_series_form image_series "TestSeries2"
    Then I am redirected to image_series list
    And I see "The image series does not have an assigned visit."

  Scenario: Assignment Successful
    Given I sign in as a user with role "Image Manager"
    When I browse to image_series list
    Then I see "Assign RS" in "TestSeries1" row
    When I click "Assign RS" in "TestSeries1" row
    Then I see "ASSIGN TO REQUIRED SERIES"
    When I check "SPECT_1"
    And I check "SPECT_2"
    And I click the "Assign Required Series" button
    Then I am redirected to image_series list
    And I see "SPECT_1 SPECT_2"
