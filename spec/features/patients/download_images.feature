Feature: Download Patient Images
  In order to retrieve a local copy of images,
  As authorized user for `download_images`,
  I can download an archive of all images of a visit.

  Background:
    Given a study "TestStudy"
    And a center "TestCenter" for "TestStudy"
    And a patient "TestPatient" for "TestCenter"
    And an image_series "TestSeries" for "TestPatient" with 10 images
    And a role "Image Manager" with permissions:
      | Study         | read                  |
      | Center        | read                  |
      | Patient       | read, download_images |

  Scenario: Not logged in
    When I browse to download_images patient "TestPatient"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as a user with all permissions
    But I cannot download_images patient
    When I browse to patient "TestPatient"
    Then I don't see "Download images"
    When I browse to download_images patient "TestPatient"
    Then I see the unauthorized page

  Scenario: Scoped System-Wide
    Given I sign in as a user with role "Image Manager"
    When I browse to patient "TestPatient"
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

  Scenario: Scoped To Study
    Given I sign in as a user with role "Image Manager" scoped to Study "TestStudy"
    When I browse to patient "TestPatient"
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
