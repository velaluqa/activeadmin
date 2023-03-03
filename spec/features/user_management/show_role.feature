Feature: Show Role
  In order oversee all permissions granted by a role,
  As authorized user for update Role,
  I can edit existing roles.

  Background:
    Given a role "Authorized Role" with permissions:
    | Role | read, create |
    And a role "Test Role" with permissions:
    | User | read_tags, create_tags, update_tags |
    | Role | update, create |
    | Center | read, destroy |

  Scenario: Hides permissions that are not granted
    When I sign in as a user with role "Authorized Role" 
    When I browse to roles list
    And I click "View" in "Test Role" row
    And I see a permission matrix row for "User" with the following unselectable permissions:
    | read_tags | create_tags | update_tags |
    And I see a permission matrix row for "Role" with the following unselectable permissions:
    | update | create |
    And I see a permission matrix row for "Center" with the following unselectable permissions:
    | read | destroy |
    Then I see a permission matrix row for "User" I don't see the following selectable permissions:
    | manage | read | update | create | destroy | generate_keypair | impersonate | confirm_mail | change_password |
    And I see a permission matrix row for "Role" I don't see the following selectable permissions:
    | manage | read | destroy | 
    And I see a permission matrix row for "Center" I don't see the following selectable permissions:
    | manage | update | comment | read_tags | update_tags | create_tags | 
