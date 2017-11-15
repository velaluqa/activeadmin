Feature: Comment Visit
  In order to discuss specifics about a visit, 
  As authorized user for `comment` visit,
  I want to add comments to a certain visit.

  Background:
    Given a study "TestStudy"
    And a center "TestCenter" for "TestStudy"
    And a patient "TestPatient" for "TestCenter"
    And a visit "1000" for "TestPatient"
    And a image_series "TestSeries" for "TestPatient"
    And an image for image series "TestSeries"
    And a role "Image Manager" with permissions:
      | Visit | read, comment |

  Scenario: Not Logged In
    When I browse to visit "1000"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user
    And I can read Study
    And I cannot comment Study
    When I browse to visit "1000"
    Then I don't see "Comment"

  Scenario: Read Comments
    Given I sign in as a user with role "Image Manager"
    When I browse to visit "1000"
    Then I see "COMMENTS (0)"
    When I fill in "Some new comment for the feature test" for "active_admin_comment_body"
    And I click the "Add Comment" button
    Then I see "COMMENTS (1)"
    And I see "Some new comment for the feature test"
