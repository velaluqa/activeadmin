Feature: Preview Email Template
  In order to see how an email template would render for a respective resource,
  As authorized user for email templates,
  I can select a resource for preview from via a rich filter dropdown.
  
  Background:
    Given a study "FooStudy"
    And a center "FooCenter" with:
      | study | FooStudy |
      | code  |       00 |
    And a patient "FooPat1" for "FooCenter"
    And a patient "BarPat2" for "FooCenter"
    And a patient "BazPat3" for "FooCenter"
    And a visit "10000" with:
      | patient     | FooPat1              |
      | visit_type  | followup             |
      | description | Visit Extraordinaire |
    And a visit "20000" with:
      | patient     | BarPat2              |
      | visit_type  | followup             |
      | description | Visit Extraordinaire |
    And an image_series "TestSeries" with:
      | patient | FooPat1 |
      | visit   |   10000 |
    And an image_series "OtherSeries" with:
      | patient | BarPat2 |
      | visit   |   20000 |
    And an email template "Test Template" with:
      """
      This is an email template:

      {{notifications.first.resource.subject_id}}
      
      of Center and Study

      {{notifications.first.resource.center.code}}

      {{notifications.first.resource.center.study.name}}
      """

  Scenario: Filter-Search and Preview Patient
    Given a role "Authorized Role" with permissions:
      | Study         | read |
      | Patient       | read |
      | ImageSeries   | read |
      | EmailTemplate | read |
    When I sign in as a user with role "Authorized Role"
    And I browse to email_template "Test Template"
    And I search "patient" for select for "Resource for Preview"
    Then I see select "Resource for Preview" with options:
      | 00FooPat1 |
      | 00BarPat2 |
      | 00BazPat3 |
    When I search "patient foo" for select for "Resource for Preview"
    Then I see select "Resource for Preview" with options:
      | 00FooPat1 |
    When I select "FooPat1" for "Resource for Preview"
    Then I see the rendered email template with:
     """
     This is an email template:
     FooPat1
     of Center and Study
     00
     FooStudy
     """
    

