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
      | BackgroundJob | read                  |
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

  Scenario: Success
    Given I sign in as a user with role "Image Manager"
    When I browse to visit "1000"
    Then I see "Download images"
    When I click link "Download images"
    Then I am redirected to the latest background_job
    And I see "Your download will be available shortly."
    When I wait for all jobs in "DownloadImagesWorker" queue
    And I browse to the latest background_job
    Then I see "Zip file Download"
    When I click link "Download"
    Then I download zip file
    # TODO: Test zip file content
