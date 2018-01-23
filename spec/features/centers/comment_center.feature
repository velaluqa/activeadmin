Feature: Comment Center
  In order to discuss specifics about a center,
  As authorized user for `comment` center,
  I want to add comments to a certain center.

  Background:
    Given a study "TestStudy"
    And a center "TestCenter" for "TestStudy"
    And a patient "TestPatient" for "TestCenter"
    And a visit "1000" for "TestPatient"
    And a image_series "TestSeries" for "TestPatient"
    And an image for image series "TestSeries"
    And a role "Image Manager" with permissions:
      | Center   | read, comment         |

  Scenario: Not Logged In
    When I browse to center "TestCenter"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot comment Center
    When I browse to center "TestCenter"
    Then I don't see "COMMENTS (0)"

  Scenario: Read Comments
    Given I sign in as a user with role "Image Manager"
    When I browse to center "TestCenter"
    Then I see "COMMENTS (0)"
    When I fill in "Some new comment for the feature test" for "active_admin_comment_body"
    And I click the "Add Comment" button
    Then I see "COMMENTS (1)"
    And I see "Some new comment for the feature test"
