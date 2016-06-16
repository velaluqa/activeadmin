@selenium
Feature: List Accessible Studies
  In order to quickly start some actions on studies,
  As a User,
  I want to see my accessible studies. 

  Background: 
    Given I am signed in as a user
    And I can access studies

  Scenario: No Studies Accessible
    Given I browse to the dashboard
    Then I should see "You do not have any accessible studies" in the studies list

  Scenario: Studies Accessible
    Given there is a study called Test Study
    And I browse to the dashboard
    Then I should see study "Test Study" in the studies list
    And I should see the link to select a study
    
