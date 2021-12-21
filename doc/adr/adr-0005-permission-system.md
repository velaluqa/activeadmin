# ADR - Role-based Permission System

## Status

`ACCEPTED`

## Context

The strict role-based permissions with hard-coded "abilities" was to
rigid. This is why a more flexible role-based permission management
was implemented.

Admin users can create, edit and delete roles. Each role can be
configured to grant a specific set of actions on specific system
resources.

## Decision

- The user authentication is implemented in the Rails web application
  using the `devise` gem; `devise` provides a user
  management/authentication component, including password management,
  user lock, and enforcement of password changes.
- user authorization is implemented via `cancan` gem; `cancan`
  provides an authorization component, based on a custom `Ability`
  definition which specifies the rights for each user per resource.
- ERICA components implemented inside the web application query
  `cancan` as to the users rights whenever a restricted action is
  requested
- Permissions are granted for each action on a specific subject (e.g.
  create `Study` or assign_visit for an `ImageSeries`)
- Roles can be configured to have a specific set of permissions
- Users can be assigned to multiple roles within the system
- ERICA components outside the web application query the user and
  rights management system via the API

## Consequences

- Permission Management only happens within the Rails web application
