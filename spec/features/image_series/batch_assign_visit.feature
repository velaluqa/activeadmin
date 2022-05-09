# user_requirement: 
# user_role: Authenticated User
# goal: Assign image series to a visit
# category: Image Management
# components:
#   - image series
Feature: Batch Assign Visit
  In order to quickly assign a set of image series to a visit,
  As user is granted `image_series/assign_visit`,
  I can batch assign selected image series from the image series list to a visit.

  Background:
    Given a study "TestStudy"
    And a center "TestCenter" with:
      | study | TestStudy |
      | code  | 10        |
    And a patient "TestPatient" for "TestCenter"
    And a visit "10000" with:
      | patient     | TestPatient          |
      | visit_type  | followup             |
      | description | Visit Extraordinaire |
    And an image_series "TestSeries" with:
      | patient | TestPatient |
    And a role "Image Manager" with permissions:
      | Study       | read               |
      | Center      | read               |
      | Patient     | read               |
      | Visit       | read               |
      | ImageSeries | read, assign_visit |

  Scenario: Not Logged In
    When I browse to image_series list
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized to assign visit
    Given I sign in as a user with all permissions
    But I cannot assign_visit image_series
    When I browse to image_series list
    And I select row of "TestSeries"
    And I click "Batch Actions"
    Then I don't see "Assign Selected Series to Visit"

  Scenario: Not same patient
    Given a patient "SecondPatient" for "TestCenter"
    And an image_series "SecondSeries" with:
      | patient | SecondPatient |
    And I sign in as a user with role "Image Manager"
    When I browse to image_series list
    And I select row of "TestSeries"
    And I select row of "SecondSeries"
    And I click "Batch Actions"
    Then I see "Assign Selected Series to Visit"
    When I click link "Assign Selected Series to Visit"
    And I click "OK"
    Then I see "Not all selected image series belong to the same patient. Batch assignment can only be used for series from one patient which are not currently assigned to a visit."
    Then I see a row for "TestSeries" with the following columns:
      | Visit |   |
    Then I see a row for "SecondSeries" with the following columns:
      | Visit |   |

  Scenario: Not unassigned
    Given an image_series "AssignedSeries" with:
      | patient | TestPatient |
      | visit   |       10000 |
    And I sign in as a user with role "Image Manager"
    When I browse to image_series list
    Then I see a row for "AssignedSeries" with the following columns:
      | Visit | 10TestPatient#10000 |
    When I select row of "TestSeries"
    And I select row of "AssignedSeries"
    And I click "Batch Actions"
    Then I see "Assign Selected Series to Visit"
    When I click link "Assign Selected Series to Visit"
    And I click "OK"
    Then I see "Not all selected image series are currently unassigned. Batch assignment can only be used for series from one patient which are not currently assigned to a visit."
    Then I see a row for "TestSeries" with the following columns:
      | Visit |   |
    Then I see a row for "AssignedSeries" with the following columns:
      | Visit | 10TestPatient#10000 |

  Scenario: Success
    Given I sign in as a user with role "Image Manager"
    When I browse to image_series list
    And I select row of "TestSeries"
    And I click "Batch Actions"
    Then I see "Assign Selected Series to Visit"
    When I click link "Assign Selected Series to Visit"
    Then I see "This will modify all selected image series. Are you sure?"
    When I click "OK"
    Then I see "Assign to Visit"
    When I select "10000" from "Visit"
    And I click the "Assign" button
    Then I see a row for "TestSeries" with the following columns:
      | Visit | 10TestPatient#10000 |
