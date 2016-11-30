## Liquid Basics

### Introduction

<%= render(partial: 'admin/help/email_templates/basics/introduction').html_safe %>

### Operators

<%= render(partial: 'admin/help/email_templates/basics/operators').html_safe %>

### Truthy & Falsy

<%= render(partial: 'admin/help/email_templates/basics/truthy_and_falsy').html_safe %>

### Types

<%= render(partial: 'admin/help/email_templates/basics/types').html_safe %>

### Whitespace

<%= render(partial: 'admin/help/email_templates/basics/whitespace').html_safe %>

## Liquid Tags

**Tags** create the logic and control flow for templates. They are denoted by curly braces and percent signs: `{%` and `%}`.

The markup used in tags does not produce any visible text. This means that you can assign variables and create conditions and loops without showing any of the Liquid logic on the generated output.

### Control Flow Tags

<%= render(partial: 'admin/help/email_templates/tags/control_flow').html_safe %>

### Iteration Tags

<%= render(partial: 'admin/help/email_templates/tags/iteration').html_safe %>

### Variable Tags

<%= render(partial: 'admin/help/email_templates/tags/variable').html_safe %>

## Liquid Filters

<%= render(partial: 'admin/help/email_templates/filters/intro').html_safe %>

### Array Filters

<%=
  render(
    partial: 'admin/help/email_templates/filters/array',
	locals: {
	  test_studies: [
		  FactoryGirl.build(:study, name: 'Study 1'),
		  FactoryGirl.build(:study, name: 'Study 2'),
		  FactoryGirl.build(:study, name: 'Study 3')
	  ],
	  test_study: Study.where(id: 1).first
	}
  ).html_safe
%>

### Math Filters

<%= render(partial: 'admin/help/email_templates/filters/math').html_safe %>

### String Filters

<%= render(partial: 'admin/help/email_templates/filters/string').html_safe %>

### URL Filters

<%=
  render(
    partial: 'admin/help/email_templates/filters/url',
	locals: {
	  test_studies: Study.all,
	  test_study: Study.where(id: 1).first
	}
  ).html_safe
%>

### Number Filters

<%= render(partial: 'admin/help/email_templates/filters/number').html_safe %>

### Other Filters

<%= render(partial: 'admin/help/email_templates/filters/other').html_safe %>

## Liquid Objects

Most ERICA database records can be accessed from within email
templates. The following list of objects defines available attributes
and relationships accessible from within email templates.

### BackgroundJob
### Center
### Erica
### Image
### ImageSeries
### Notification
### NotificationProfile
### Patient
### Permission
### Role
### Study
### User
### UserRole
### Version
### Visit

## Accessible Data

The type of the `EmailTemplate` defines which data is accessible
within the email template.

Currently there is only the type `NotificationProfile`.

### Type: NotificationProfile
