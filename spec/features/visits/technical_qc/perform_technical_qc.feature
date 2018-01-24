Feature: Perform Technical Quality Control
  In order to ensure technical quality of assigned image series,
  As authorized user for `perform_technical_qc` for a visit,
  I want to perform answer defined question catalog for a required series.

  Background: 
    Given a study "TestStudy" with configuration
      """
      visit_types:
        baseline: 
          description: A simple visit type
          required_series:
            - 
        followup: 
          description: A simple visit type
          required_series: []
      """
    And a center "TestCenter" for "TestStudy"
    And a patient "TestPatient" for "TestCenter"
    And a visit "10000" with:
      | patient     | TestPatient          |

  # Scenario: Not logged in
  # Scenario: Unauthorized
  # Scenario: Success; Technical QC negative
  # Scenario: Success; Technical QC positive
