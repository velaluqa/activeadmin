Feature: Manage Background Job
  In order to manage background jobs,
  As authorized user for `download_images`,
  I can download an archive of all images of a visit.

  Background:
    Given a study "TestStudy"
    And a center "TestCenter" for "TestStudy"
    And a patient "TestPatient" for "TestCenter"
    And an image_series "TestSeries" for "TestPatient" with 10 images
    And a role "Background Job Manager" with permissions:
      | BackgroundJob | manage |
    And a user "h.maulwurf"
    And a user "m.mustermann"
    And a background job "Test Job for h.maulwurf" for user "h.maulwurf"
    And a background job "Test Job for m.mustermann" for user "m.mustermann"

  Scenario: Not logged in
    When I browse to download_images patient "TestPatient"
    Then I see "PLEASE SIGN IN"

  Scenario: Unauthorized
    Given I sign in as user "h.maulwurf"
    When I browse to BackgroundJob list
    Then I see "Test Job for h.maulwurf"
    But I don't see "Test Job for m.mustermann"

  Scenario: Scoped System-Wide
    Given user "h.maulwurf" belongs to role "Background Job Manager"
    And I sign in as user "h.maulwurf"
    When I browse to BackgroundJob list
    Then I see "Test Job for h.maulwurf"
    But I see "Test Job for m.mustermann"

  Scenario: Scoped To Study
    Given user "h.maulwurf" belongs to role "Background Job Manager" scoped to study "TestStudy"
    And I sign in as user "h.maulwurf"
    When I browse to BackgroundJob list
    Then I see "Test Job for h.maulwurf"
    But I see "Test Job for m.mustermann"
