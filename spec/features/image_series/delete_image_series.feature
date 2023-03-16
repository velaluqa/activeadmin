Feature: Delete ImageSeries
  In order to remove image_series that are false or obsolete,
  As authorized user for deletion of image_series,
  I can delete an image_series.

  Background:
    Given an image_series "Test Series"
    And a role "Authorized Role" with permissions:
      | ImageSeries  | read, destroy        |
      | Version      | read                 |

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot destroy image_series
    When I browse to image_series list
    Then I don't see a "Delete" link in row for "Test Series"
    When I browse to image_series "Test Series"
    Then I don't see "Delete Image Series"

  Scenario: Delete from index list page saves comment for audittrail
    When I sign in as a user with role "Authorized Role"
    And I browse to image_series list
    Then I see a row with "Test Series"
    When I click link "Delete"
    And I provide "This is a comment" for browser prompt and confirm
    And I browse to image_series list
    Then I don't see a row with "Test Series"
    When I click "Audit Trail" in the navigation menu
    And I click "View" in the first "ImageSeries" row
    Then I see "This is a comment" in "Comment" row

  Scenario: Delete from show page saves comment for audittrail
    When I sign in as a user with role "Authorized Role"
    And I browse to image_series "Test Series"
    And I click link "Delete Image Series"
    And I provide "This is a comment" for browser prompt and confirm
    And I browse to image_series list
    Then I don't see a row with "Test Series"
    When I click "Audit Trail" in the navigation menu
    And I click "View" in the first "ImageSeries" row
    Then I see a row with "This is a comment"