Feature: Create Simple Image Series Tags
  In order to mark image_series on the fly with new tags while managing image_series,
  As authorized user for `create_tags` ImageSeries,
  I want to create tags from the select box when updating tags.

  Background:
    Given an image_series "Test Series"
    And a role "Authorized Role" with permissions:
      | ImageSeries | read, read_tags, update_tags, create_tags |
    And a role "Unauthorized Role" with permissions:
      | ImageSeries | read, read_tags |

  Scenario: Authorized to create tags
    When I sign in as a user with role "Authorized Role" 
    And I browse to image_series "Test Series" 
    Then I see "Add Tags" 
    When I click "Add Tags" 
    Then I see "Tags" 
    When I search "newtag" for "Tags" and select "newtag" 
    And I click "Submit" 
    Then I see "newtag" in "Tags" row

  Scenario: Unauthorized to create tags
    When I sign in as a user with role "Unauthorized Role" 
    And I browse to image_series "Test Series" 
    Then I don't see "Add Tags" 
    