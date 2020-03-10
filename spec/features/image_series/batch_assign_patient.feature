Feature: Batch Assign Patient
  In order to quickly assign a set of image series to a patient,
  As user is granted `image_series/assign_patient`,
  I can batch assign selected image series from the image series list to a patient.

  Background:
    Given a study "TestStudy"
    And a center "TestCenter" with:
      | study | TestStudy |
      | code  | 10        |
    And a patient "TestPatient" for "TestCenter"
    And a patient "AssignedPatient" for "TestCenter"
    And a visit "10000" with:
      | patient     | TestPatient          |
      | visit_type  | followup             |
      | description | Visit Extraordinaire |
    And an image_series "TestSeries" with:
      | patient | AssignedPatient |
    And a role "Image Manager" with permissions:
      | Study       | read                 |
      | Center      | read                 |
      | Patient     | read                 |
      | ImageSeries | read, assign_patient |

  Scenario: Not Logged In
    When I browse to image_series list
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized to assign patient
    Given I sign in as a user with all permissions
    But I cannot assign_patient image_series
    When I browse to image_series list
    And I select row for "TestSeries"
    And I click "Batch Actions"
    Then I don't see "Assign Selected Series to Patient"

  Scenario: Not same study
    Given a study "SecondStudy"
    And a center "SecondCenter" with:
      | study | SecondStudy |
      | code  |         300 |
    And a patient "SecondPatient" for "SecondCenter"
    And an image_series "SecondSeries" with:
      | patient | SecondPatient |
    And I sign in as a user with role "Image Manager"
    When I browse to image_series list
    And I select row for "TestSeries"
    And I select row for "SecondSeries"
    And I click "Batch Actions"
    Then I see "Assign Selected Series to Patient"
    When I click link "Assign Selected Series to Patient"
    And I click "OK"
    Then I see "Not all selected image series belong to the same study. Batch assignment can only be used for series of the same study."
    Then I see the following values for row with "TestSeries":
      | Patient | 10AssignedPatient |
    Then I see the following values for row with "SecondSeries":
      | Patient | 300SecondPatient   |

  Scenario: Not all with unassigned visit
    Given an image_series "SeriesWithVisit" with:
      | patient | TestPatient |
      | visit   |       10000 |
    And I sign in as a user with role "Image Manager"
    When I browse to image_series list
    And I select row for "TestSeries"
    And I select row for "SeriesWithVisit"
    And I click "Batch Actions"
    Then I see "Assign Selected Series to Patient"
    When I click link "Assign Selected Series to Patient"
    And I click "OK"
    Then I see "Not all selected image series are currently unassigned. Batch assignment can only be used for series which are not currently assigned to a visit."
    Then I see the following values for row with "TestSeries":
      | Patient | 10AssignedPatient |
    Then I see the following values for row with "SeriesWithVisit":
      | Patient | 10TestPatient |

  Scenario: Success
    Given I sign in as a user with role "Image Manager"
    When I browse to image_series list
    Then I see the following values for row with "TestSeries":
      | Patient | 10AssignedPatient |
    When I select row for "TestSeries"
    And I click "Batch Actions"
    Then I see "Assign Selected Series to Patient"
    When I click link "Assign Selected Series to Patient"
    And I click "OK"
    Then I see "Assign to Patient"
    When I select "TestPatient" from "Patient"
    And I click the "Assign" button
    Then I see the following values for row with "TestSeries":
      | Patient | 10TestPatient |
      
