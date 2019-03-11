Feature: Comment Study
  In order to discuss specifics about a study,
  As authorized user for `comment` study,
  I want to add comments to a certain study.

  Background:
    Given a study "TestStudy"
    And a center "TestCenter" for "TestStudy"
    And a patient "TestPatient" for "TestCenter"
    And a visit "1000" for "TestPatient"
    And a image_series "TestSeries" for "TestPatient"
    And an image for image series "TestSeries"
    And a role "Image Manager" with permissions:
      | Study         | read, comment         |

  Scenario: Not Logged In
    When I browse to study "TestStudy"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot comment Study
    When I browse to study "TestStudy"
    Then I don't see "COMMENTS (0)"

  Scenario: Read Comments
    Given I sign in as a user with role "Image Manager"
    When I browse to study "TestStudy"
    Then I see "COMMENTS (0)"
    When I fill in "active_admin_comment_body" with "Some new comment for the feature test"
    And I click the "Add Comment" button
    Then I see "COMMENTS (1)"
    And I see "Some new comment for the feature test"
