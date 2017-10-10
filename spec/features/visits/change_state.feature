Feature: Change State
  In order to manage quality control process,
  As authorized user to update state of visits,
  I can update the state of a visit.

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
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
      | Visit   | read, update_state   |

  Scenario: Not logged in
    When I browse to edit_state_form visit "10000"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user
    And I can read visits
    And I cannot update_state visits
    When I browse to show visit "10000"
    Then I don't see "Change State"
    When I browse to edit_state_form visit "10000"
    Then I see the unauthorized page

  Scenario: State Change Successful
    Given I sign in as a user with role "Image Manager"
    When I browse to show visit "10000"
    And I click link "Change State"
    Then I see 'State'
    When I select "Complete, tQC of all series passed" from "State"
    And I click the "Update Visit" button
    Then I am redirected to show visit "10000"
    And I see "State COMPLETE, T QC OF ALL SERIES PASSED"
