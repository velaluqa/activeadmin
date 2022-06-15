Feature: View User Roles
   In order to verify the permission of a user to view roles,
   we want to allow only authorized users the ability to view the roles of other users within the system.

   Background:
     Given a role "Authorized" with permissions:
        | User       | read |
        | Role       | read |
        | UserRole   | read |
     And a user "authorized.user" with:
        | name | Alex Authorized |
     And user "authorized.user" belongs to role "Authorized" 
     And a role "Unauthorized" with permissions:
        | User | read |
     And a user "other.user" with:
        | name | Udo Unauthorized |
     And user "other.user" belongs to role "Unauthorized" 

   Scenario: Unauthorized to view other user's role
     When I sign in as user "other.user"
     And I browse to users list
     Then I don't see "Roles" in "Alex Authorized" row
     When I click "View" in "Alex Authorized" row
     Then I don't see a row with "Roles"
   
   Scenario: Authorized to view other user's role
     When I sign in as user "authorized.user"
     And I browse to users list
     Then I see "1 Roles" in "Udo Unauthorized" row
     When I click "View" in "Udo Unauthorized" row
     Then I see "1 Roles" in "Roles" row
     When I click "1 Roles" in "Roles" row
     Then I see a row with "Unauthorized"
