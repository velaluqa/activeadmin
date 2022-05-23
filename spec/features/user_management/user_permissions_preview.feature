Feature: Preview User Permissions
  In order to quickly see all permissions a user is granted through all its roles,
  As authorized user to `read users`,
  I want to display a permission matrix just like the one for independent roles with all permissions the user has.

  Background:
    Given a study "FooStudy"
    And a center "FooCenter" for "FooStudy"
    And a patient "FooPatient" for "FooCenter"
    And a study "BarStudy"
    And a center "BarCenter" for "BarStudy"
    And a patient "BarPatient" for "BarCenter"
    And a role "Authorized Role" with permissions:
      | User | read |
    And a user "authorized.user" with role "Authorized Role"
    And a user "inspectable.user" 
    And a role "Manager" with permissions:
      | Study | manage |
    And a role "System-wide role" with permissions:
      | Study   | read |
      | Center  | read |
      | Patient | read |
    And a role "Scoped to study role" with permissions:
      | Study   | read, update |
      | Center  | read, update |
      | Patient | read, update |

  Scenario: System-wide and Scoped to one study
    Given user "inspectable.user" belongs to role "System-wide role" 
    And user "inspectable.user" belongs to role "Scoped to study role" scoped to study "FooStudy" 
    When I sign in as user "authorized.user" 
    And I browse to show user "inspectable.user" 
    Then I see "Preview Permissions" 
    When I click link "Preview Permissions" 
    Then I see checked permission "read" for resource "Study" 
    And I see checked permission "update *" for resource "Study" 
    And I see checked permission "read" for resource "Center" 
    And I see checked permission "update *" for resource "Center" 
    And I see checked permission "read" for resource "Patient" 
    And I see checked permission "update *" for resource "Patient" 
    When I hover over permission "read" for resource "Study"
    Then I see "read granted system-wide"
    When I hover over permission "update *" for resource "Study"
    Then I see "update granted for:"
    And I see "- Study: FooStudy"
    But I don't see "BarStudy"

  Scenario: System-wide and Scoped to two studies
    Given user "inspectable.user" belongs to role "System-wide role" 
    And user "inspectable.user" belongs to role "Scoped to study role" scoped to study "FooStudy" 
    And user "inspectable.user" belongs to role "Scoped to study role" scoped to study "BarStudy" 
    When I sign in as user "authorized.user" 
    And I browse to show user "inspectable.user" 
    Then I see "Preview Permissions" 
    When I click link "Preview Permissions" 
    Then I see checked permission "read" for resource "Study" 
    And I see checked permission "update *" for resource "Study" 
    And I see checked permission "read" for resource "Center" 
    And I see checked permission "update *" for resource "Center" 
    And I see checked permission "read" for resource "Patient" 
    And I see checked permission "update *" for resource "Patient" 
    When I hover over permission "read" for resource "Study"
    Then I see "read granted system-wide"
    When I hover over permission "update *" for resource "Study"
    Then I see "update granted for:"
    And I see "- Study: FooStudy, BarStudy"

  Scenario: System-wide manage overrides all respective permissions
    Given user "inspectable.user" belongs to role "Manager" 
    When I sign in as user "authorized.user" 
    And I browse to show user "inspectable.user" 
    Then I see "Preview Permissions" 
    When I click link "Preview Permissions" 
    Then I see checked permission "manage" for resource "Study" 
    And I see checked permission "read" for resource "Study" 
    And I see checked permission "update" for resource "Study" 
    And I see checked permission "create" for resource "Study" 
    And I see checked permission "destroy" for resource "Study" 
    And I see checked permission "comment" for resource "Study" 
    And I see checked permission "read_reports" for resource "Study" 
    And I see checked permission "configure" for resource "Study" 
    And I see checked permission "clean_dicom_metadata" for resource "Study" 
