Feature: Update Image Series Tags
  In order to manage tags of an image series,
  As authorized user for `update_tags` for image series,
  I can add and remove tags for an image series.

  Background:
    Given an image_series "First ImageSeries" with:
      | tags | my_tag |  
    And an image_series "Second ImageSeries" with:
      | tags | other_tag |  
    And a role "Authorized Role" with permissions:
      | ImageSeries | read, read_tags, update_tags |
    And a role "Unauthorized Role" with permissions:
      | ImageSeries | read, read_tags |

  Scenario: Authorized to update tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to image_series list
    Then I see "my_tag" in "First ImageSeries" row
    But I don't see "other_tag" in "First ImageSeries" row
    When I click the pencil icon in "First ImageSeries" row
    When I search "other_tag" for "Tags" and select "other_tag" 
    And I click "Submit" 
    Then I see "my_tag" in "First ImageSeries" row
    And I see "other_tag" in "First ImageSeries" row

  Scenario: Unauthorized to update tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to image_series list
    Then I see "my_tag" in "First ImageSeries" row
    And I see "other_tag" in "Second ImageSeries" row
    But I don't see the edit pencil icon in "First ImageSeries" row
    And I don't see the edit pencil icon in "Second ImageSeries" row
    