Feature: Assign Required Series
  In order to mark image series for quality control,
  As authorized user for assign required series,
  I can assign an image series to a required series from the visit view.

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
      | visit   |      10000 |
    And a role "Image Manager" with permissions:
      | Study   | read                         |
      | Center  | read, update                 |
      | Patient | read, update, create         |
      | Visit   | read, assign_required_series |

  Scenario: Not logged in
    When I browse to assign_required_series_form visit "10000" with:
      | required_series_names | SPECT_1 |
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user
    And I cannot assign_required_series visits
    When I browse to assign_required_series_form visit "10000" with:
      | required_series_names | SPECT_1 |
    Then I see the unauthorized page

  Scenario: Assignment Successful
    Given I sign in as a user with role "Image Manager"
    When I browse to assign_required_series_form visit "10000" with:
      | required_series_names | SPECT_1 |
    Then I see "SPECT_1"
    And I don't see "SPECT_2"
    When I select "TestSeries" from "SPECT_1"
    And I click the "Assign" button
    Then I am redirected to show visit "10000"
    And I see "SPECT_1 TESTSERIES PENDING"
