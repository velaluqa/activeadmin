Feature: Download Own Private Key
  In order to save my own private key,
  As authenticated user with a private key,
  I can download the private key file to my computer.

  Background:
    Given a role "Authorized" with permissions:
      | User | manage |
    And a user "other.user" with role "Authorized"
    And a user "current.user" with role "Authorized"
    
  Scenario: Allows download for current user
    When I sign in as user "current.user"
    And I browse to users list
    And I click "View" in "current.user" row
    Then I see "Download Private Key"
    
  Scenario: Denies download for other users
    When I sign in as user "current.user"
    And I browse to users list
    And I click "View" in "other.user" row
    Then I don't see "Download Private Key"
    When I browse to download_private_key for user "other.user"
    Then I see "not authorized"
