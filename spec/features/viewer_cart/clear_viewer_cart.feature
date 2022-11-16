Feature: Clear a viewer cart
  In order to clear a viewer cart containing a resource (e.g ImageSeries),
  As an authorized user I can clear the viewer cart

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

  Scenario: Authorised to clear the viewer cart for image_series
    When I sign in as user "authorized.user"
    And I browse to image_series list
    And I select row of "TestSeries"
    And I click "Batch Actions"
    Then I see "Add To Viewer Cart Selected"
    When I click link "Add To Viewer Cart Selected"
    Then I see "added to viewer cart"
    When I click "Viewer Cart" in the navigation menu
    Then I see "TestSeries"
    And I see "Clear Cart"
    When I click "Clear Cart"
    And I confirm popup
    Then I see "Viewer cart cleared."
    And I don't see "TestSeries"

  Scenario: Authorised to clear the viewer cart for centers
    When I sign in as user "authorized.user"
    And I browse to centers list
    And I select row of "FooCenter"
    And I click "Batch Actions"
    Then I see "Add To Viewer Cart Selected"
    When I click link "Add To Viewer Cart Selected"
    Then I see "added to viewer cart"
    When I click "Viewer Cart" in the navigation menu
    Then I see "FooCenter"
    And I see "Clear Cart"
    When I click "Clear Cart"
    And I confirm popup
    Then I see "Viewer cart cleared."
    And I don't see "FooCenter"

  Scenario: Authorised to clear the viewer cart for studies
    When I sign in as user "authorized.user"
    And I browse to studies list
    And I select row of "FooStudy"
    And I click "Batch Actions"
    Then I see "Add To Viewer Cart Selected"
    When I click link "Add To Viewer Cart Selected"
    Then I see "added to viewer cart"
    When I click "Viewer Cart" in the navigation menu
    Then I see "FooStudy"
    And I see "Clear Cart"
    When I click "Clear Cart"
    And I confirm popup
    Then I see "Viewer cart cleared."
    And I don't see "FooStudy"

  Scenario: Authorised to clear the viewer cart for patient
    When I sign in as user "authorized.user"
    And I browse to patients list
    And I select row of "FooPatient"
    And I click "Batch Actions"
    Then I see "Add To Viewer Cart Selected"
    When I click link "Add To Viewer Cart Selected"
    Then I see "added to viewer cart"
    When I click "Viewer Cart" in the navigation menu
    Then I see "FooPatient"
    And I see "Clear Cart"
    When I click "Clear Cart"
    And I confirm popup
    Then I see "Viewer cart cleared."
    And I don't see "FooPatient"

  Scenario: Authorised to clear the viewer cart for visits
    When I sign in as user "authorized.user"
    And I browse to visits list
    And I select row of "10000"
    And I click "Batch Actions"
    Then I see "Add To Viewer Cart Selected"
    When I click link "Add To Viewer Cart Selected"
    Then I see "added to viewer cart"
    When I click "Viewer Cart" in the navigation menu
    Then I see "10000"
    And I see "Clear Cart"
    When I click "Clear Cart"
    And I confirm popup
    Then I see "Viewer cart cleared."
    And I don't see "10000"

  Scenario: Unauthorised to clear the viewer cart
    When I sign in as user "other.user"
    Then I see the navigation menu for "Udo Unauthorized" with entries:
      | Studies           |
      | Centers           |
      | Patients          |
      | Visits            |
      | Image Series      |
    But I don't see "Viewer Cart" in the navigation menu
    And I don't see "Batch Actions" in image_series list
    And I don't see "Batch Actions" in studies list
    And I don't see "Batch Actions" in visits list
    And I don't see "Batch Actions" in patients list
    And I don't see "Batch Actions" in centers list
    