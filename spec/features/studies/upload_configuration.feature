Feature: Upload Configuration
  In order to configure a study,
  As authenticated user for `upload_config` for Study,
  I can upload a YAML file as study configuration.

  - removing visit types causes forcable notice
  - removing required series causes forcable notice

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
    And a role "Study Manager" with permissions:
      | Study   | read, create, update, destroy, configure |

  Scenario: Not Logged In
    When I browse to upload_config_form study "FooStudy"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user
    And I can read Study
    And I cannot configure Study
    When I browse to study "FooStudy"
    Then I don't see "Upload configuration"
    When I browse to upload_config_form study "FooStudy"
    Then I see the unauthorized page

  Scenario: Invalid Study Configuration
    Given I sign in as a user with role "Study Manager"
    When I browse to study "FooStudy"
    Then I see "Upload configuration"
    When I follow link "Upload configuration"
    Then I see "UPLOAD CONFIGURATION"
    When I provide string for file field "Configuration File"
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
      """
    And I click the "Upload Configuration" button
    Then I see "key 'image_series_properties:' is required"

  Scenario: Remove Existing Visit Types
    Given I sign in as a user with role "Study Manager"
    When I browse to study "FooStudy"
    Then I see "Upload configuration"
    When I follow link "Upload configuration"
    Then I see "UPLOAD CONFIGURATION"
    When I provide string for file field "Configuration File"
      """
      visit_types:
        baseline: 
          required_series: {}
      image_series_properties: []
      """
    And I click the "Upload Configuration" button
    Then I see "removed visit types will be deleted from all visits: followup"
    When I check "Force"
    And I click the "Upload Configuration" button
    Then I see "Configuration successfully uploaded"

  Scenario: Remove Existing Required Series
    Given I sign in as a user with role "Study Manager"
    When I browse to study "FooStudy"
    Then I see "Upload configuration"
    When I follow link "Upload configuration"
    Then I see "UPLOAD CONFIGURATION"
    When I provide string for file field "Configuration File"
      """
      visit_types:
        baseline: 
          required_series: {}
        followup: 
          required_series:
            SPECT_1:
              tqc: []
      image_series_properties: []
      """
    And I click the "Upload Configuration" button
    Then I see "removed required series will be deleted from all visits: followup/SPECT_2"
    When I check "Force"
    And I click the "Upload Configuration" button
    Then I see "Configuration successfully uploaded"

  Scenario: Success
    Given I sign in as a user with role "Study Manager"
    When I browse to study "FooStudy"
    Then I see "Upload configuration"
    When I follow link "Upload configuration"
    Then I see "UPLOAD CONFIGURATION"
    When I provide string for file field "Configuration File"
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
            SPECT_3:
              tqc: []
        followup2: 
          required_series:
            SPECT_1:
              tqc: []
            SPECT_2:
              tqc: []
      image_series_properties: []
      """
    And I click the "Upload Configuration" button
    Then I see "Configuration successfully uploaded"
