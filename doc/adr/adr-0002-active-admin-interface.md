# ADR - Active Admin Interface

## Status

`ACCEPTED`

## Context

The primary operations within ERICA SaaS are CRUD-like (e.g. `create`,
`read`, `update` & `destroy`). These operations are performed on the
basic resources for image management (e.g. studies, centers, patients,
visits, image series, etc.).

As these are standard operations the following options were considered:

- develop a custom UI from the ground up
- use a framework for quick UI iteration

## Decision

ERICA SaaS is based on Active Admin as its central user interface.
Active Admin is a Ruby on Rails framework that provides most CRUD-like
interactions with Ruby on Rails models for enterprise applications.

* The administrative interface is implemented in the Rails web
  application using the `activeadmin` ruby gem. `activeadmin` is a
  framework for implementing administrative-style user interfaces
  providing a set of view types, user interface (UI) components and
  features useful for such interfaces (like “view”, “delete”).
* Most UI parts of the administrative interface are implemented using
  components supplied by `activeadmin`. These are defined in terms of
  an `activeadmin`-specific DSL (domain specific language).
* `activeadmin` queries the User/Rights management system for user
  authentication (only authenticated users can access the system) and
  action authorization.
* `activeadmin` accesses the Data Storage via Ruby on Rails components
  for data storage access (see below, Data Storage).
* `activeadmin` accesses the Image Storage via direct file-system and
  file access using core ruby functionality.
* `activeadmin` uses `dcmtk` to access DICOM files. The DICOM ToolKit
  (dcmtk) package consists of source code, documentation and
  installation instructions for a set of software libraries and
  applications implementing part of the DICOM Standard.

## Consequences

ERICA SaaS is limited by the possibilities of classical web
applications (request and response), but development within this
category are supported well.

