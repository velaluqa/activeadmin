Feature: User Login
  Background:
    Given there is a monster

  Scenario: attack the monster
    When I attack it
    Then it should die
