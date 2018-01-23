Feature: Reassign Visit
  In order to keep existing required series assignments,
  As an authorized user to assign_visit to image series,
  I am asked whether to override or reset required series assignments when assigning a different visit.

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
      | patient     | FooPatient  |
      | visit_type  | followup    |
      | description | Basic Visit |
    And a visit "20000" with:
      | patient     | FooPatient       |
      | visit_type  | baseline         |
      | description | Other Visit Type |
    And a visit "30000" with:
      | patient     | FooPatient                       |
      | visit_type  | followup                         |
      | description | Already assigned required series |
    And a visit "40000" with:
      | patient     | FooPatient  |
      | visit_type  | followup    |
      | description | Clean visit |
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
    And a role "Image Manager" with permissions:
      | Study       | read                    |
      | Center      | read                    |
      | Patient     | read                    |
      | ImageSeries | read, update            |
      | Visit       | read, assign_visit, mqc |

  Scenario: Different Visit Type - Removing Required Series Assignments
    Given I sign in as a user with role "Image Manager"
    When I browse to edit image_series "TestSeries1"
    And I select "20000" from "Visit"
    And I click the "Update Image series" button
    Then I see "The new visit has a different visit type than the current visit."
    When I click the "Update Image series" button
    Then I see "#20000"
    When I browse to visit "20000"
    Then I see "SPECT_3 MISSING"
    Then I see "SPECT_4 MISSING"

  Scenario: Same Visit Type - Moving tQC results 
    Given I sign in as a user with role "Image Manager"
    When I browse to edit image_series "TestSeries1"
    And I select "40000" from "Visit"
    And I click the "Update Image series" button
    Then I see "#40000"
    When I browse to visit "10000"
    Then I see "SPECT_1 MISSING"
    When I browse to visit "40000"
    Then I see "SPECT_1 TESTSERIES1 PASSED"
    When I click link "View tQC results"
    Then I see "Comment Overriding tQC results"

  Scenario: Same Visit Type - Overriding Required Series Assignments
    Given I sign in as a user with role "Image Manager"
    When I browse to edit image_series "TestSeries1"
    And I select "30000" from "Visit"
    And I click the "Update Image series" button
    Then I see "The following required series in the new visit will have their assignment and tQC results overwritten by this change: SPECT_1."
    When I click the "Update Image series" button
    Then I see "#30000"
    When I browse to visit "10000"
    Then I see "SPECT_1 MISSING"
    When I browse to visit "30000"
    Then I see "SPECT_1 TESTSERIES1 PASSED"
    When I click link "View tQC results"
    Then I see "Comment Overriding tQC results"
