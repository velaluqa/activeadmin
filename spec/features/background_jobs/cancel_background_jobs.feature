Feature: Cancel a running background job
  In order to manage background jobs,
  As authorized user,
  I can cancel a running background job for a process (e.g images download for a patient).

  Background:
    Given a center "TestCenter" with:
      | code | 1 |
    And a patient "TestPatient" for "TestCenter"
    And a role "Background Job Manager" with permissions:
      | BackgroundJob | read, cancel              |
      | Patient       | read, download_images     |
    And a role "Unauthorized" with permissions:
      | BackgroundJob | read                      |
      | Patient       | read, download_images     |

  Scenario: Authorised to cancel a running job
    When I sign in as a user with role "Background Job Manager"
    And I browse to download_images patient "TestPatient"
    And I browse to BackgroundJob list
    Then I see "Download images for patient 1TestPatient"
    When I click "View" in "Download images for patient 1TestPatient" row
    Then I see "Cancel Background Job"
    When I click link "Cancel Background Job"
    And I wait for all jobs in "DownloadImagesWorker" queue 
    And I see "CANCELLED" in "State" row

  Scenario: Unauthorised to kill a running background job
    When I sign in as a user with role "Unauthorized"
    And I browse to download_images patient "TestPatient"
    And I browse to BackgroundJob list
    Then I see "Download images for patient 1TestPatient"
    When I click "View" in "Download images for patient 1TestPatient" row
    Then I don't see "Cancel Background Job"