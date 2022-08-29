Feature: Read image_series by tags
  As authorized user for `read_tags` for image_series,
  I can see the tags for the image_series.

  Background:
    Given an image_series "First ImageSeries" with:
      | tags | my_tag, other_tag |  
    And an image_series "Second ImageSeries" with:
      | tags | other_image_series_tag |  
    And a role "Authorized Role" with permissions:
      | ImageSeries | read, read_tags |
    And a role "Unauthorized Role" with permissions:
      | ImageSeries | read |

  Scenario: Authorized to read image_series tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to image_series list
    Then I see "my_tag" in "First ImageSeries" row
    And I see "other_image_series_tag" in "Second ImageSeries" row
    When I click "View" in "First ImageSeries" row
    Then I see "my_tag" in "Tags" row 
    And I see "other_tag" in "Tags" row

  Scenario: Unauthorized to read image_series tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to image_series list
    Then I don't see "my_tag" in "First ImageSeries" row
    And I don't see "other_image_series_tag" in "Second ImageSeries" row
    
