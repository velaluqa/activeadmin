@poltergeist @javascript
Feature: List Accessible Studies
  In order to quickly start some actions on studies,
  As a User,
  I want to see my accessible studies. 

  Background: 
    Given I sign in as a user

  Scenario: Not authorized, No studies available
    When I browse to the dashboard
    Then I see "No studies found."

  Scenario: Not authorized, Studies available
    Given a study "Test Study"
    When I browse to the dashboard
    Then I see "No studies found."

  Scenario: Authorized, No studies available
    Given I can read_reports study
    When I browse to the dashboard
    Then I see "No studies found."

  Scenario: Authorized, Studies available
    Given I can read_reports Study
    And a study "Test Study"
    When I browse to the dashboard
    Then I see "Test Study"
    And I see the link to select a study
    
  Scenario: Authorized for reports and upload
    Given a study "Test Study"
    Given I can read_reports Study
    And I can upload ImageSeries
    When I browse to the dashboard
    Then I see "Test Study"
    And I see the link to initiate image upload
    And I see the link to select a study
