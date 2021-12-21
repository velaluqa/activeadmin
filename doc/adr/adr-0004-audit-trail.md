# ADR - Audit Trail

## Status

`ACCEPTED`

## Context

All changes within the system must be monitored and tracked.

## Decision

* Internal component, logs all changes to the Data Storage.
* Logged data can be accessed via the Administrative Interface.
* Access via the Administrative Interface is subject to User/Rights management.
* The Administrative Interface contains views to access this
  information for individual ERICA resources or groups of resources.

The audit trail is implemented in the Ruby on Rails web application,
using the “paper_trail” as well as the “git” version control system.

* The “paper_trail” gem logs all changes to ERICA resources stored in
  the SQL RDBMS into a SQL table which can be accessed via the Data
  Storage model layer.
* The “git” version control system is used to track changes to YAML
  configuration files used by the ERICA system, namely for studies.

## Consequences

* Git and PostGres need to be kept consistent; Changes may only be
  performed by ERICA SaaS
* Configuration files can only be loosely associated with database
  records (e.g. in the business logic instead of database schema
  constraints)
