# user_requirement:
# user_role: Authenticated User
# goal: To retrieve results of long running background jobs.
# category: Background Jobs
# components:
#   - sidekiq
# side_effects:
#   - log to audit trail
Feature: Destroying Background Jobs
  In order to manage background jobs,
  As authorized user for `destroy`, background jobs
  I can destroy any background job.

  Background:
    Given a study "TestStudy"
    And a center "TestCenter" for "TestStudy"
    And a patient "TestPatient" for "TestCenter"
    And an image_series "TestSeries" for "TestPatient" with 10 images
    And a role "Background Job Manager" with permissions:
      | BackgroundJob | read, destroy                  |
    And a user "h.maulwurf"
    And a user "m.mustermann"
    And a background job "Test Job for h.maulwurf" for user "h.maulwurf"
    And a background job "Test Job for m.mustermann" for user "m.mustermann"

  Scenario: Unauthorized to destroy background job
    When I sign in as user "h.maulwurf"
    And I browse to BackgroundJob list
    Then I see "Test Job for h.maulwurf"
    But I don't see "Test Job for m.mustermann"
    When I click "View" in "Test Job for h.maulwurf" row
    Then I don't see "Delete Background Job"

  Scenario: Authorized to destroy any background job
    Given user "h.maulwurf" belongs to role "Background Job Manager"
    When I sign in as user "h.maulwurf"
    And I browse to BackgroundJob list
    Then I see "Test Job for h.maulwurf"
    And I see "Test Job for m.mustermann"
    When I click "View" in "Test Job for h.maulwurf" row
    Then I see "Delete Background Job"
    When I click link "Delete Background Job"
    And I confirm alert
    Then I see "Running jobs cannot be deleted!"
