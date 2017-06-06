Feature: List Required Series
  In order to manage a visit,
  As authorized user,
  I want to see a list of required series and their assignment status, when I look at a visit
 
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
    And study "FooStudy" is locked
    And a center "FooCenter" for "FooStudy"
    And a patient "FooPatient" for "FooCenter"
    And a visit "10000" with:
      | patient     | FooPatient    |
      | description | No visit type |
    And a visit "20000" with:
      | patient     | FooPatient                            |
      | visit_type  | foobar                                |
      | description | Visit type not in study configuration |
    And a visit "30000" with:
      | patient     | FooPatient                         |
      | visit_type  | baseline                           |
      | description | Visit type without required series |
    And a visit "40000" with:
      | patient     | FooPatient                      |
      | visit_type  | followup                        |
      | description | Visit type with required series |
    And a role "Image Manager" with permissions:
      | Study   | read                 |
      | Center  | read, update         |
      | Patient | read, update, create |
      | Visit   | read                 |

  Scenario: No Visit Type Assigned
    Given I sign in as a user with role "Image Manager"
    When I browse to visit "10000"
    Then I see "Assign a visit type to manage required series."

  Scenario: Assigned Visit Type Not In Study Configuration
    Given I sign in as a user with role "Image Manager"
    When I browse to visit "20000"
    Then I see "Assigned visit type not found in study configuration. Maybe the study configuration changed in the meantime. Reassign a valid visit type to manage required series."

  Scenario: No Required Series Available
    Given I sign in as a user with role "Image Manager"
    When I browse to visit "30000"
    Then I see "The study configuration does not provide any required series for this visit type."

  Scenario: Required Series Available
    Given I sign in as a user with role "Image Manager"
    When I browse to visit "40000"
    Then I see "SPECT_1"
    Then I see "SPECT_2"
