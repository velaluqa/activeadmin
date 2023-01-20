Feature: Filter image_series by tags
  In order to filter according to configurable labels (i.e. Tags)
  As authorized user for `read_tags` for image_series,
  I can filter for certain tags in the system.

  Background:
    Given an image_series "First ImageSeries" with:
      | tags | my_tag, other_tag |  
    And an image_series "Second ImageSeries" with:
      | tags | other_image_series_tag |  
    And a role "Authorized Role" with permissions:
      | ImageSeries | read, read_tags |
    And a role "Unauthorized Role" with permissions:
      | ImageSeries | read |

  Scenario: Authorized to filter image_series by tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to image_series list
    Then I see "my_tag" in "First ImageSeries" row
    And I see "other_image_series_tag" in "Second ImageSeries" row
    When I click "View Filters"
    And I select "my_tag" for "Tags"
    And I click "Filter"
    Then I see "First ImageSeries"
    But I don't see "Second ImageSeries"

  Scenario: Unauthorized to filter image_series by tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to image_series list
    Then I don't see "Tags"
    
