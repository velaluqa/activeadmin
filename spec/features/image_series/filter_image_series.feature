# user_requirement: 
# user_role: Authenticated User
# goal: Filter image series
# category: Image Management
# components:
#   - image_series
Feature: Filter Image Series
  In order to find specific image series,
  As authorized user for `read image series`,
  I can restrict the image series displayed to me by filtering by various properties.
  
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
    
  Scenario: Filter by study
    When I sign in as a user with role "Authorized Role"
    And I browse to image_series list
    Then I see "FooImageSeries"
    And I see "BarImageSeries"
    When I search "Foo" for "Resource" and select "Study: FooStudy"
    And I click "Filter"
    Then I see "FooImageSeries"
    But I don't see "BarImageSeries"
    When I click "Clear Filters"
    Then I see "FooImageSeries"
    And I see "BarImageSeries"

    
  

