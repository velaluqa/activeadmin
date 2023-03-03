Feature: Create Role
  In order to grant permissions,
  As authorized user for create Role,
  I can create new roles.

  Background:
    Given a role "Authorized Role" with permissions:
    | Role | read, create |

  Scenario: Show all available permissions
    When I sign in as a user with role "Authorized Role" 
    When I browse to roles list
    And I click "New Role"
    When I fill in "Title" with "Test Role"
    Then I see a permission matrix row for "BackgroundJob" with the following selectable permissions:
    | manage | read | destroy | cancel |
    And I see a permission matrix row for "Sidekiq" with the following selectable permissions:
    | manage |
    And I see a permission matrix row for "Configuration" with the following selectable permissions:
    | manage | read |
    And I see a permission matrix row for "Study" with the following selectable permissions:
     | manage | read | update | destroy | comment | read_reports | read_tags | create_tags | update_tags | configure | clean_dicom_metadata | change_domino_config |
    And I see a permission matrix row for "Center" with the following selectable permissions:
    | manage  | read | update | destroy | comment | read_tags | update_tags | create_tags | 
    And I see a permission matrix row for "Patient" with the following selectable permissions:
      | manage | read | update | destroy | comment | read_tags | update_tags | create_tags |
    And I see a permission matrix row for "ImageSeries" with the following selectable permissions:
     | manage | read | update | destroy | comment | read_tags | update_tags | create_tags |
    And I see a permission matrix row for "FormSession" with the following selectable permissions:
    | manage | read | update | create | destroy |
    And I see a permission matrix row for "FormDefinition" with the following selectable permissions:
    | manage | read | update | create | destroy |
    And I see a permission matrix row for "FormAnswer" with the following selectable permissions:
    | manage | read | update | create | destroy |
    And I see a permission matrix row for "NotificationProfile" with the following selectable permissions:
     | manage | read | update | destroy | simulate_recipients |
    And I see a permission matrix row for "Notification" with the following selectable permissions:
    | manage | read | create | destroy |
    And I see a permission matrix row for "User" with the following selectable permissions:
     | manage | read | update | create | destroy | generate_keypair | impersonate | confirm_mail | change_password | read_tags | create_tags | update_tags |
    And I see a permission matrix row for "UserRole" with the following selectable permissions:
    | manage | read | update | create | destroy |
    And I see a permission matrix row for "PublicKey" with the following selectable permissions:
    | manage | read | update | create | destroy |
    And I see a permission matrix row for "RequiredSeries" with the following selectable permissions:
    | manage | read |
    And I see a permission matrix row for "Role" with the following selectable permissions:
    | manage | read | update | create | destroy | 
    And I see a permission matrix row for "Visit" with the following selectable permissions:
    | manage | read | update | create | destroy | comment | download_images | read_tags | update_tags | create_tags | create_from_template | update_state | assign_required_series | read_tqc | perform_tqc | read_mqc | perform_mqc |
    And I see a permission matrix row for "Version" with the following selectable permissions:
    | manage | read |
    Then I check permission "read" for resource "Version"
    Then I check permission "create" for resource "Visit"
    And I click "Create Role"
    Then I see "Role was successfully created."
