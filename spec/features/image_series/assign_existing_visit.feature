# user_requirement: 
# user_role: Authenticated User
# goal: Assign image series to a visit
# category: Image Management
# components:
#   - image series
Feature: Assign Visit
  In order to mark an image series as candidate for quality control,
  As authorized user that can assign image series to visits,
  I can assign an image series to a visit.

  Background:
    Given a study "FooStudy" with configuration
      """
      visit_types:
        baseline: 
          required_series:
            SPECT_3:
              tqc: []
            SPECT_4:
              tqc: []
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
      | Study          | read                      |
      | Center         | read                      |
      | Patient        | read                      |
      | Visit          | read, read_tqc            |
      | RequiredSeries | read                      |
      | ImageSeries    | read, assign_visit        |

  Scenario: Not logged in
    When I browse to assign_visit_form image_series "TestSeries"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot assign_visit image_series
    When I browse to image_series list
    Then I don't see "Assign Visit"
    When I browse to assign_visit_form image_series "TestSeries"
    Then I see the unauthorized page

  Scenario: Different Visit Type - Removing Required Series Assignments
    Given a visit "20000" with:
      | patient     | FooPatient       |
      | visit_type  | baseline         |
      | description | Other Visit Type |
    And an image_series "TestSeries1" with:
      | patient | FooPatient     |
      | visit   | 10000          |
      | state   | visit_assigned |
    When I sign in as a user with role "Image Manager"
    And I browse to image_series list
    And I click "Assign Visit" in "TestSeries1" row
    And I select "20000" from "Visit"
    And I click "Assign Visit"
    Then I see "The new visit has a different visit type than the current visit."
    When I click "Assign Visit"
    Then I see "#20000" in "Visit" row
    When I browse to visit "20000"
    Then I see "SPECT_3 MISSING"
    Then I see "SPECT_4 MISSING"
    
  Scenario: Same Visit Type - Moving tQC results
    Given a visit "40000" with:
      | patient     | FooPatient  |
      | visit_type  | followup    |
      | description | Clean visit |
    And an image_series "TestSeries1" with:
      | patient | FooPatient     |
      | visit   | 10000          |
      | state   | visit_assigned |
    And visit "10000" has required series "SPECT_1" assigned to "TestSeries1"
    And visit "10000" required series "SPECT_1" has tQC with:
      | comment | Overriding tQC results |
    When I sign in as a user with role "Image Manager"
    And I browse to image_series list
    And I click "Assign Visit" in "TestSeries1" row
    And I select "40000" from "Visit"
    And I click "Assign Visit"
    Then I see "#40000" in "Visit" row
    When I browse to visit "10000"
    Then I see "SPECT_1 MISSING"
    When I browse to visit "40000"
    Then I see "SPECT_1 TESTSERIES1 PASSED"
    When I click link "View tQC results"
    Then I see "Comment Overriding tQC results"
  
  Scenario: Same Visit Type - Overriding Required Series Assignments
    Given a visit "30000" with:
      | patient     | FooPatient                       |
      | visit_type  | followup                         |
      | description | Already assigned required series |
    And an image_series "TestSeries1" with:
      | patient | FooPatient     |
      | visit   | 10000          |
      | state   | visit_assigned |
    And an image_series "TestSeries2" with:
      | patient | FooPatient     |
      | visit   | 30000          |
      | state   | visit_assigned |
    And visit "10000" has required series "SPECT_1" assigned to "TestSeries1"
    And visit "10000" required series "SPECT_1" has tQC with:
      | comment | Overriding tQC results |
    And visit "30000" has required series "SPECT_1" assigned to "TestSeries1"
    And visit "30000" required series "SPECT_1" has tQC with:
      | comment | tQC results |
    When I sign in as a user with role "Image Manager"
    And I browse to image_series list
    And I click "Assign Visit" in "TestSeries1" row
    And I select "30000" from "Visit"
    And I click "Assign Visit"
    Then I see "The following required series in the new visit will have their assignment and tQC results overwritten by this change: SPECT_1."
    And I click "Assign Visit"
    Then I see "#30000"
    When I browse to visit "10000"
    Then I see "SPECT_1 MISSING"
    When I browse to visit "30000"
    Then I see "SPECT_1 TESTSERIES1 PASSED"
    When I click link "View tQC results"
    Then I see "Comment Overriding tQC results"

  Scenario: Unassigned - Assign Existing Visit
    Given I sign in as a user with role "Image Manager"
    When I browse to image_series list
    Then I see "Assign Visit"
    When I click "Assign Visit" in "TestSeries" row
    Then I see "ASSIGN VISIT"
    When I select "FooPatient#10000" from "Visit"
    And I click the "Assign Visit" button
    Then I am redirected to image_series "TestSeries"
    And I see "FooPatient#10000"
