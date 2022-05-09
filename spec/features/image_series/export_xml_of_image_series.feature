Feature: Export XML of Image Series
  In order to extract data from the system for other purposes
  As authorized user for `read image series`,
  I want to download the image series as XML.

  Background:
    Given a study "FooStudy"
    And a center "FooCenter" for "FooStudy"
    And a patient "FooPatient" for "FooCenter"
    And a visit "10000" for "FooPatient"
    And an image_series "FooImageSeries" with:
      | patient     | FooPatient |
      | visit       |      10000 |
      | image_count |          1 |
    Given a study "BarStudy"
    And a center "BarCenter" for "BarStudy"
    And a patient "BarPatient" for "BarCenter"
    And a visit "20000" for "BarPatient"
    And an image_series "BarImageSeries" with:
      | patient     | BarPatient |
      | visit       |      20000 |
      | image_count |          1 |
    And a role "Authorized Role" with permissions:
      | Study       | read |
      | Center      | read |
      | Patient     | read |
      | Visit       | read |
      | ImageSeries | read |
    
  Scenario: No filters
    When I sign in as a user with role "Authorized Role"
    And I browse to image_series list 
    And I click "XML"
    Then I see the following "<image-series>" xml entries:
      | name           |
      | FooImageSeries |
      | BarImageSeries |
    And I see "<image-series>" xml entries with the following attributes: 
      | id                 |
      | name               |
      | visit-id           |
      | created-at         |
      | updated-at         |
      | patient-id         |
      | imaging-date       |
      | domino-unid        |
      | series-number      |
      | state              |
      | comment            |
      | properties         |
      | properties-version |
      | tag-list           |
