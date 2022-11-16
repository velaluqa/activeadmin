Feature: Start viewer for a viewer cart resource
  In order to commence the `start viewer` for a resource (e.g ImageSeries),
  As an authorized user I can use the `start viewer` of the viewer cart

  Background:
    Given a study "FooStudy"
    And a center "FooCenter" 
    And a patient "FooPatient"
    And a visit "10000" 
    And an image_series "TestSeries"
    And a role "Cart Manager" with permissions:
      | Study       | read                 |
      | Center      | read                 |
      | Patient     | read                 |
      | Visit       | read                 |
      | ImageSeries | read, viewer         |
    And a user "authorized.user" with:
      | name | Alex Authorized |
    And user "authorized.user" belongs to role "Cart Manager"
    And a role "Unauthorized" with permissions:
      | Study       | read                 |
      | Center      | read                 |
      | Patient     | read                 |
      | Visit       | read                 |
      | ImageSeries | read                 |
    And a user "other.user" with:
      | name | Udo Unauthorized |
    And user "other.user" belongs to role "Unauthorized" 

  Scenario: Authorized to download .jnlp file
    When I sign in as user "authorized.user"
    And I browse to image_series list
    And I select row of "TestSeries"
    And I click "Batch Actions"
    Then I see "Add To Viewer Cart Selected"
    When I click link "Add To Viewer Cart Selected"
    Then I see "added to viewer cart"
    When I click "Viewer Cart" in the navigation menu
    Then I see "TestSeries"
    When I click "Start Viewer"
    Then I don't see "Not Authorized"
    # The download should start. As JNLP files cause a warning about 
    # potential harm to the device they cannot be downloaded and 
    # tested automatically.