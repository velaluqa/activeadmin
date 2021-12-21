# user_requirement: 
# user_role: Authenticated User
# goal: Assign image series to a required series
# category: Image Management
# components:
#   - study
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
      | Study   | read                                   |
      | Center  | read, update                           |
      | Patient | read, update, create                   |
      | Visit   | read, assign_required_series, read_tqc |

  Scenario: Not logged in
    When I browse to assign_required_series_form visit "10000" with:
      | required_series_names | SPECT_1 |
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    And I cannot assign_required_series visits
    When I browse to visit "10000"
    Then I don't see "Assign Required Series"
    And I don't see an "Assign" link in row for "SPECT_1"
    When I browse to assign_required_series_form visit "10000" with:
      | required_series_names | SPECT_1 |
    Then I see the unauthorized page

  # TODO: Extract Feature: Reassign Required Series
  # TODO: Scenario: Assign via visit action
  # TODO: Scenario: Assign via `Assign` link from required series table

  Scenario: Assignment Successful
    Given I sign in as a user with role "Image Manager"
    When I browse to visit "10000"
    Then I see "Assign Required Series"
    And I see an "Assign" link in row for "SPECT_1"
    When I browse to assign_required_series_form visit "10000" with:
      | required_series_names | SPECT_1 |
    Then I see "SPECT_1"
    And I don't see "SPECT_2"
    When I select "TestSeries" from "SPECT_1"
    And I click the "Assign" button
    Then I am redirected to show visit "10000"
    And I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PENDING    |
