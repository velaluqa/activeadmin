Feature: Update Image Series with patient and visit
  In order to ensure consistency and a better user experience,
  As authorized user to edit image series,
  I only see visit options in the select for the selected patient when I am in the edit image series form.

  Background:
    Given a study "FooStudy"
    And a center "FooCenter" with:
      | study | FooStudy |
      | code  |       10 |
    And a patient "FooPatient" for "FooCenter"
    And a patient "BarPatient" for "FooCenter"
    And a visit "10000" with:
      | patient     | FooPatient           |
      | visit_type  | followup             |
      | description | Visit Extraordinaire |
    And a visit "20000" with:
      | patient     | BarPatient           |
      | visit_type  | followup             |
      | description | Visit Extraordinaire |
    And an image_series "TestSeries" with:
      | patient | FooPatient       |
      | visit   | 10000            |
    And a role "Authorized Role" with permissions:
      | ImageSeries | read, reassign_patient, assign_visit |

  Scenario: Unauthorized to assign visit or reassign patient
    When I sign in as a user with all permissions
    But I cannot assign_visit image_series
    And I cannot reassign_patient image_series
    When I browse to image_series list
    And I click "Edit" in "TestSeries" row
    Then I see "DETAILS"
    And I see "10FooPatient"
    But I don't see the "Patient" field
    And I see "FooPatient#10000"
    But I don't see the "Visit" field

  Scenario: Unauthorized to assign visit but can assign patient
    When I sign in as a user with all permissions
    And I cannot assign_visit image_series
    When I browse to image_series list
    And I click "Edit" in "TestSeries" row
    Then I see "DETAILS"
    And I see "FooPatient#10000"
    But I don't see the "Visit" field
    When I select "FooPatient" from "Patient"
    And I click the "Update Image series" button
    Then I see "Image series was successfully updated."
    And I see a row with "FooPatient"
  
  Scenario: Unauthorized to assign patient but can assign visit
    When I sign in as a user with all permissions
    But I cannot reassign_patient image_series
    When I browse to image_series list
    And I click "Edit" in "TestSeries" row
    Then I see "DETAILS"
    And I see "FooPatient"
    But I don't see the "Patient" field
    When I select "FooPatient#10000" from "Visit"
    And I click the "Update Image series" button
    Then I see "Image series was successfully updated."
    And I see "FooPatient#10000" in "Visit" row

  Scenario: Only show visit options for the selected patient
    When I sign in as a user with all permissions
    When I browse to image_series list
    And I click "Edit" in "TestSeries" row
    Then I see "DETAILS"
    And I see select "Patient" with options:
      | 10FooPatient |
      | 10BarPatient |
    And I see select "Visit" with options:
      | FooPatient#10000 |
    But I see select "Visit" without options:
      | BarPatient#20000 |
    When I select "10BarPatient" from "Patient"
    Then I see select "Visit" without options:
      | FooPatient#10000 |
    But I see select "Visit" with options:
      | BarPatient#20000 |

  # Scenario: Reassign patient and visit - visit was not assigned - Don't show message
  # Scenario: Reassign patient and visit - visit was assigned - visit data (tqc, mqc) is invalidated
  # Scenario: Reassign patient without visit - visit was not assigned - Don't show message
  # Scenario: Reassign patient without visit - visit was assigned - visit data (tqc, mqc) is invalidated
