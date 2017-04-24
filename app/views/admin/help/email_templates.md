<%-
  locals = {
    test_studies: [
  	  FactoryGirl.build(:study, name: 'Study 1'),
  	  FactoryGirl.build(:study, name: 'Study 2'),
  	  FactoryGirl.build(:study, name: 'Study 3')
  	],
  	test_study: Study.first || FactoryGirl.build(:study, id: 1, name: 'Sophisticated Test Study', created_at: (DateTime.now - 2.days))
  }
-%>

## Liquid Basics

### Introduction

<%= render(partial: 'admin/help/email_templates/basics/introduction', locals: locals).html_safe %>

### Operators

<%= render(partial: 'admin/help/email_templates/basics/operators', locals: locals).html_safe %>

### Truthy & Falsy

<%= render(partial: 'admin/help/email_templates/basics/truthy_and_falsy', locals: locals).html_safe %>

### Types

<%= render(partial: 'admin/help/email_templates/basics/types', locals: locals).html_safe %>

### Whitespace

<%= render(partial: 'admin/help/email_templates/basics/whitespace', locals: locals).html_safe %>

## Liquid Tags

**Tags** create the logic and control flow for templates. They are denoted by curly braces and percent signs: `{%` and `%}`.

The markup used in tags does not produce any visible text. This means that you can assign variables and create conditions and loops without showing any of the Liquid logic on the generated output.

### Control Flow Tags

<%= render(partial: 'admin/help/email_templates/tags/control_flow', locals: locals).html_safe %>

### Iteration Tags

<%= render(partial: 'admin/help/email_templates/tags/iteration', locals: locals).html_safe %>

### Variable Tags

<%= render(partial: 'admin/help/email_templates/tags/variable', locals: locals).html_safe %>

## Liquid Filters

<%= render(partial: 'admin/help/email_templates/filters/intro', locals: locals).html_safe %>

### Array Filters

<%= render(partial: 'admin/help/email_templates/filters/array', locals: locals).html_safe %>

### Math Filters

<%= render(partial: 'admin/help/email_templates/filters/math', locals: locals).html_safe %>

### String Filters

<%= render(partial: 'admin/help/email_templates/filters/string', locals: locals).html_safe %>

### URL Filters

<%= render(partial: 'admin/help/email_templates/filters/url', locals: locals).html_safe %>

### Number Filters

<%= render(partial: 'admin/help/email_templates/filters/number', locals: locals).html_safe %>

### Other Filters

<%= render(partial: 'admin/help/email_templates/filters/other', locals: locals).html_safe %>

## Liquid Objects

Most ERICA database records can be accessed from within email
templates. The following list of objects defines available attributes
and relationships accessible from within email templates.

### BackgroundJob

<%= describe_liquid_drop('BackgroundJobDrop') %>

### Center

<%= describe_liquid_drop('CenterDrop') %>

### Image

<%= describe_liquid_drop('ImageDrop') %>

### ImageSeries

<%= describe_liquid_drop('ImageSeriesDrop') %>

### Notification

<%= describe_liquid_drop('NotificationDrop') %>

### NotificationProfile

<%= describe_liquid_drop('NotificationProfileDrop') %>

### Patient

<%= describe_liquid_drop('PatientDrop') %>

### Permission

<%= describe_liquid_drop('PermissionDrop') %>

### Role

<%= describe_liquid_drop('RoleDrop') %>

### Study

<%= describe_liquid_drop('StudyDrop') %>

### User

<%= describe_liquid_drop('UserDrop') %>

### UserRole

<%= describe_liquid_drop('UserRoleDrop') %>

### Version

<%= describe_liquid_drop('VersionDrop') %>

### Visit

<%= describe_liquid_drop('VisitDrop') %>


## Accessible Data

The type of the `EmailTemplate` defines which data is accessible
within the email template.

Currently there is only the type `NotificationProfile`.

### Type: NotificationProfile

Each notification profile template has the following accessible variables:


- `notifications` — A list of notifications that should be sent with this specific e-Mail
- `user` — The recipient of this e-Mail

#### Example: Addressing the Recipient

To get the name of the recipient you can access the `user.name`
object as described
in [**Liquid Basics → Introduction → Objects**](#liquid_basics-introduction-objects).

A thorough list of accessible fields of a user can be found in
the [**Liquid Objects → User**](#liquid_objects-user) section.

The section [**Liquid Objects**](#liquid_objects) has tables for all
ERICA resources, that are accessible via email templates.

```liquid
Dear {{user.name}},

[...]

Kind Regards,

Your Pharmtrace-Team
```

#### Example: Listing Notifications in a Table

First we declare the HTML table structure:

```liquid
<table>
  <thead>
	<tr>
  	  <th>Study Name</th>
	  <th>Event</th>
	  <th></th>
	</tr>
  </thead>
  <tbody>
  <!-- rows extracted from the list of notifications -->
  </tbody>
</table>
```

To go through all notifications you typically use a `for` loop as explained in [**Liquid Tags → Iteration Tags**](#liquid_tags-iteration_tags).

```liquid
{% for notification in notifications %}
  <tr>
    <td>{{ notification.resource.name }}</td>
    <td>{{ notification.triggering_action }}</td>
    <td>{{ notification.resource | link: 'Open in ERICA' }}</td>
  </tr>
{% endfor %}
```

Within the `for` loop the `notification` references the notification
for the respective row.

A notification typically has a resource (which has previously
triggered the notification to be created). This resource can be
accessed via `{{ notification.resource }}`. Refer to
the [**Liquid Objects**](#liquid_objects) section for an overview of
the respective attributes.

In this example the `notification.resource` is of
type [`StudyDrop`](#liquid_objects-study) and we display the name of
the study in the first column of the table.

```liquid
<td>{{ notification.resource.name }}</td>
```

The second column shows the event that triggered the notification
(see [Notification attributes](#liquid_objects-notification)).

```liquid
<td>{{ notification.triggering_action }}</td>
```

In the third column we link to the study to allow opening the
respective study in the browser
(see [Liquid Filters → URL Filters](#liquid_filters-url_filters)).

```liquid
<td>{{ notification.resource | link: 'Open in ERICA' }}</td>
```

The full example would look like this:

```liquid
Dear {{user.name}},

you receive this message because you are configured as recipient for
notifications about study changes at http://study.pharmtrace.eu.

<table>
  <thead>
	<tr>
  	  <th>Study Name</th>
	  <th>Event</th>
	  <th></th>
	</tr>
  </thead>
  <tbody>
  {% for notification in notifications %}
    <tr>
      <td>{{ notification.resource.name }}</td>
      <td>{{ notification.triggering_action }}</td>
      <td>{{ notification.resource | link: 'Open in ERICA' }}</td>
    </tr>
  {% endfor %}
  </tbody>
</table>

Kind Regards,

Your Pharmtrace-Team
```
