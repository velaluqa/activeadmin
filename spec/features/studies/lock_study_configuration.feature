# user_requirement: 
# user_role: Authenticated User
# goal: Lock a study configuration for production use
# category: Study Configuration
# components:
#   - study
#   - configuration
Feature: Lock Study Configuration
  In order to work on a study with a fixed configuration,
  As authenticated user for `manage` for Study,
  I can lock an uploaded study configuration.

  Background:
    Given a study "TestStudy" with configuration
      """
      visit_types:
        baseline: 
          required_series: {}
        followup: 
          mqc:
          - id: consistency
            label: Consistent?
            type: bool
          required_series:
            SPECT_1:
              tqc:
              - id: modality
                label: 'Correct?'
                type: bool
            SPECT_2:
              tqc: []
      image_series_properties: []
      """
    And study "TestStudy" is locked
    And a center "TestCenter" for "TestStudy"
    And a patient "TestPatient" for "TestCenter"
    And a visit "10000" with:
      | patient     | TestPatient |
      | description | No visit type |
    And a visit "20000" with:
      | patient     | TestPatient                 |
      | visit_type  | foobar                                |
      | description | Visit type not in study configuration |
    And a visit "30000" with:
      | patient     | TestPatient              |
      | visit_type  | baseline                           |
      | description | Visit type without required series |
    And a visit "40000" with:
      | patient     | TestPatient           |
      | visit_type  | followup                        |
      | description | Visit type with required series |
    And a role "Study Manager" with permissions:
      | Study | manage |
      | Visit | manage |

  Scenario: Not Logged In
    When I browse to upload_config_form study "TestStudy"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot configure Study
    When I browse to study "TestStudy"
    Then I don't see "Upload configuration"
    When I browse to upload_config_form study "TestStudy"
    Then I see the unauthorized page

  Scenario: Invalid Study Configuration
    Given I sign in as a user with role "Study Manager"
    And study "TestStudy" has configuration
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
    When I browse to study "TestStudy"
    And I click "Unlock"
    And I click "Lock"
    Then I see "The study still has validation errors. These need to be fixed before the study can be locked."
    And I see "State Building"

  Scenario: Remove Existing Visit Type
    Given I sign in as a user with role "Study Manager"
    And I browse to visit "30000"
    Then I see "Visit Type baseline"
    And study "TestStudy" has configuration
      """
      visit_types:
        followup: 
          required_series:
            SPECT_1:
              tqc: []
            SPECT_2:
              tqc: []
      image_series_properties: []
      """
    When I browse to study "TestStudy"
    And I click "Unlock"
    And I click "Lock"
    Then I see "Study locked"
    When I wait for all jobs in "ConsolidateStudyConfigurationForStudyWorker" queue
    And I browse to visit "30000"
    Then I see "Visit Type Empty"

  Scenario: Add new required series to existing visit type
    Given I sign in as a user with role "Study Manager"
    And I browse to visit "40000"
    Then I see "Visit Type followup"
    And I see "SPECT_1"
    And I see "SPECT_2"
    But I don't see "SPECT_3"
    And study "TestStudy" has configuration
      """
      visit_types:
        followup: 
          required_series:
            SPECT_1:
              tqc: []
            SPECT_2:
              tqc: []
            SPECT_3:
              tqc: []
      image_series_properties: []
      """
    When I browse to study "TestStudy"
    And I click "Unlock"
    And I click "Lock"
    Then I see "Study locked"
    When I wait for all jobs in "ConsolidateStudyConfigurationForStudyWorker" queue
    And I browse to visit "40000"
    Then I see "Visit Type followup"
    And I see "SPECT_1"
    And I see "SPECT_2"
    But I see "SPECT_3"

  Scenario: Remove existing required series from existing visit type
    Given I sign in as a user with role "Study Manager"
    And I browse to visit "40000"
    Then I see "Visit Type followup"
    And I see "SPECT_1"
    And I see "SPECT_2"
    And study "TestStudy" has configuration
      """
      visit_types:
        followup: 
          required_series:
            SPECT_2:
              tqc: []
      image_series_properties: []
      """
    When I browse to study "TestStudy"
    And I click "Unlock"
    And I click "Lock"
    Then I see "Study locked"
    When I wait for all jobs in "ConsolidateStudyConfigurationForStudyWorker" queue
    And I browse to visit "40000"
    Then I see "Visit Type followup"
    And I don't see "SPECT_1"
    And I see "SPECT_2"

  Scenario: Technical Quality Control Specification Changed -> Resets tqc state
    Given I sign in as a user with role "Study Manager"
    And an image_series "TestSeries" with:
      | image_count |              1 |
      | patient     |    TestPatient |
      | visit       |          40000 |
      | state       | visit_assigned |
    And visit "40000" has required series "SPECT_1" assigned to "TestSeries"
    And visit "40000" required series "SPECT_1" has tQC with:
      | modality | passed |
    And I browse to visit "40000"
    Then I see "Visit Type followup"
    And I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PASSED     |
    And I see "SPECT_2"
    And study "TestStudy" has configuration
      """
      visit_types:
        followup: 
          required_series:
            SPECT_1:
              tqc:
              - id: modality
                label: 'Really Correct?'
                type: bool
            SPECT_2:
              tqc: []
      image_series_properties: []
      """
    When I browse to study "TestStudy"
    And I click "Unlock"
    And I click "Lock"
    Then I see "Study locked"
    When I wait for all jobs in "ConsolidateStudyConfigurationForStudyWorker" queue
    And I browse to visit "40000"
    Then I see "Visit Type followup"
    And I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PENDING    |
    And I see "SPECT_2"

  Scenario: Technical Quality Control Specification Did Not Change
    Given I sign in as a user with role "Study Manager"
    And an image_series "TestSeries" with:
      | image_count |              1 |
      | patient     |    TestPatient |
      | visit       |          40000 |
      | state       | visit_assigned |
    And visit "40000" has required series "SPECT_1" assigned to "TestSeries"
    And visit "40000" required series "SPECT_1" has tQC with:
      | modality | passed |
    And I browse to visit "40000"
    Then I see "Visit Type followup"
    And I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PASSED     |
    And I see "SPECT_2"
    And study "TestStudy" has configuration
      """
      visit_types:
        followup: 
          required_series:
            SPECT_1:
              tqc:
              - id: modality
                label: 'Correct?'
                type: bool
            SPECT_2:
              tqc: []
      image_series_properties: []
      """
    When I browse to study "TestStudy"
    And I click "Unlock"
    And I click "Lock"
    Then I see "Study locked"
    When I wait for all jobs in "ConsolidateStudyConfigurationForStudyWorker" queue
    And I browse to visit "40000"
    Then I see "Visit Type followup"
    And I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PASSED     |
    And I see "SPECT_2"
    
  Scenario: Medical Quality Control Specification Changed
    Given I sign in as a user with role "Study Manager"
    And an image_series "TestSeries" with:
      | image_count |              1 |
      | patient     |    TestPatient |
      | visit       |          40000 |
      | state       | visit_assigned |
    And visit "40000" has required series "SPECT_1" assigned to "TestSeries"
    And visit "40000" required series "SPECT_1" has tQC with:
      | modality | passed |
    And visit "40000" has mQC with:
      | consistency | passed |
    And I browse to visit "40000"
    Then I see "Visit Type followup"
    And I see "M Qc State PERFORMED, PASSED"
    And I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PASSED     |
    And I see "SPECT_2"
    And study "TestStudy" has configuration
      """
      visit_types:
        followup:
          mqc:
          - id: consistency
            label: Really consistent?
            type: bool
          required_series:
            SPECT_1:
              tqc:
              - id: modality
                label: 'Correct?'
                type: bool
            SPECT_2:
              tqc: []
      image_series_properties: []
      """
    When I browse to study "TestStudy"
    And I click "Unlock"
    And I click "Lock"
    Then I see "Study locked"
    When I wait for all jobs in "ConsolidateStudyConfigurationForStudyWorker" queue
    And I browse to visit "40000"
    Then I see "Visit Type followup"
    And I see "M Qc State PENDING"
    And I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PASSED     |
    And I see "SPECT_2"

  Scenario: Medical Quality Control Specification Did Not Change
    Given I sign in as a user with role "Study Manager"
    And an image_series "TestSeries" with:
      | image_count |              1 |
      | patient     |    TestPatient |
      | visit       |          40000 |
      | state       | visit_assigned |
    And visit "40000" has required series "SPECT_1" assigned to "TestSeries"
    And visit "40000" required series "SPECT_1" has tQC with:
      | modality | passed |
    And visit "40000" has mQC with:
      | consistency | passed |
    And I browse to visit "40000"
    Then I see "Visit Type followup"
    And I see "M Qc State PERFORMED, PASSED"
    And I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PASSED     |
    And I see "SPECT_2"
    And study "TestStudy" has configuration
      """
      visit_types:
        followup:
          mqc:
          - id: consistency
            label: Consistent?
            type: bool
          required_series:
            SPECT_1:
              tqc:
              - id: modality
                label: 'Correct?'
                type: bool
            SPECT_2:
              tqc: []
      image_series_properties: []
      """
    When I browse to study "TestStudy"
    And I click "Unlock"
    And I click "Lock"
    Then I see "Study locked"
    When I wait for all jobs in "ConsolidateStudyConfigurationForStudyWorker" queue
    And I browse to visit "40000"
    Then I see "Visit Type followup"
    And I see "M Qc State PERFORMED, PASSED"
    And I see a row with "SPECT_1" and the following columns:
      | Assigned Image Series | TESTSERIES |
      | tQC State             | PASSED     |
    And I see "SPECT_2"
