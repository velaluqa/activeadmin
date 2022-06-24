# user_requirement: 
# user_role: Authenticated User
# goal: Download images of a specific visit
# category: Export
# components:
#   - visit
#   - download worker
Feature: Download Visit Images
  In order to retrieve a local copy of images,
  As authorized user for `download_images`,
  I can download an archive of all images of a visit.

  Background:
    Given a study "TestStudy" with configuration
      """
      visit_types:
        baseline: 
          required_series:
            SPECT_1:
              tqc: []
      image_series_properties: []
      """
    And a center "TestCenter" for "TestStudy"
    And a patient "TestPatient" for "TestCenter"
    And an image_series "TestSeries" for "TestPatient" with 10 images
    And a visit "1000" with:
      | patient     | TestPatient   |
      | visit_type  | baseline      |
      | description | No visit type |
    And a required series "SPECT_1" for visit "1000" with:
      | image_series | TestSeries |
    And a role "Image Manager" with permissions:
      | Study         | read                  |
      | Center        | read                  |
      | Patient       | read                  |
      | Visit         | read, download_images |

  Scenario: Not logged in
    When I browse to "/admin/visits/1/download_images"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot download_images visits
    When I browse to visit "1000"
    Then I don't see "Download images"
    When I browse to download_images visit "1000"
    Then I see the unauthorized page

  Scenario: Scoped System-Wide
    Given I sign in as a user with role "Image Manager"
    When I browse to visit "1000"
    Then I see "Download images"
    When I click link "Download images"
    Then I am redirected to the latest background_job
    And I see "Your download will be available shortly."
    When I wait for all jobs in "DownloadImagesWorker" queue
    Then I see "COMPLETED" in "State" row
    And I see "Zip file Download"
    When I click link "Download"
    Then I download zip file
    # TODO: Test zip file content

  Scenario: Scoped to study
    Given I sign in as a user with role "Image Manager" scoped to Study "TestStudy"
    When I browse to visit "1000"
    Then I see "Download images"
    When I click link "Download images"
    Then I am redirected to the latest background_job
    And I see "Your download will be available shortly."
    When I wait for all jobs in "DownloadImagesWorker" queue
    Then I see "COMPLETED" in "State" row
    And I see "Zip file Download"
    When I click link "Download"
    Then I download zip file
    # TODO: Test zip file content

