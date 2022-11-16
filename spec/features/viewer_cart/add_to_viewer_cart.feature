Feature: Add to viewer cart
  In order to add a `resource` (e.g ImageSeries) to viewer cart,
  As an authorized user I can add a resource to the viewer cart

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
    And a role "Unauthorised" with permissions:
      | Study       | read                 |
      | Center      | read                 |
      | Patient     | read                 |
      | Visit       | read                 |
      | ImageSeries | read                 |
    
  Scenario: Authorised to add a study to viewer cart
    When I sign in as a user with role "Cart Manager"
    And I browse to studies list
    And I select row of "FooStudy"
    And I click "Batch Actions"
    Then I see "Add To Viewer Cart Selected"
    When I click link "Add To Viewer Cart Selected"
    Then I see "added to viewer cart"

  Scenario: Authorised to add an image_series to viewer cart
    When I sign in as a user with role "Cart Manager"
    And I browse to image_series list
    And I select row of "TestSeries"
    And I click "Batch Actions"
    Then I see "Add To Viewer Cart Selected"
    When I click link "Add To Viewer Cart Selected"
    Then I see "added to viewer cart"
  
  Scenario: Authorised to add a center to viewer cart
    When I sign in as a user with role "Cart Manager"
    And I browse to centers list
    And I select row of "FooCenter"
    And I click "Batch Actions"
    Then I see "Add To Viewer Cart Selected"
    When I click link "Add To Viewer Cart Selected"
    Then I see "added to viewer cart"
  
  Scenario: Authorised to add a patient to viewer cart
    When I sign in as a user with role "Cart Manager"
    And I browse to patients list
    And I select row of "FooPatient"
    And I click "Batch Actions"
    Then I see "Add To Viewer Cart Selected"
    When I click link "Add To Viewer Cart Selected"
    Then I see "added to viewer cart"
  
  Scenario: Authorised to add a visit to viewer cart
    When I sign in as a user with role "Cart Manager"
    And I browse to visits list
    And I select row of "10000"
    And I click "Batch Actions"
    Then I see "Add To Viewer Cart Selected"
    When I click link "Add To Viewer Cart Selected"
    Then I see "added to viewer cart"

  Scenario: Unauthorised to add a resource (e.g image_series) to viewer cart
    When I sign in as a user with role "Unauthorised"
    Then I don't see "Batch Actions" in image_series list
    And I don't see "Batch Actions" in studies list
    And I don't see "Batch Actions" in visits list
    And I don't see "Batch Actions" in patients list
    And I don't see "Batch Actions" in centers list


    

