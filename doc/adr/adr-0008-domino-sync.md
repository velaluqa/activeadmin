# ADR - Domino Sync

## Status

`ACCEPTED`

## Context

Pharmtrace uses IBM Lotus Domino-based project management. In order to
integrate imaging processes with other pharmtrace-internal processes
ERICA SaaS information must be synced to Lotus Notes.

## Decision

* Interface between ERICAstore and the IBM Lotus Domino-based project
  management system
* Supplies ERICA data to project management system
* The domino sync is implemented as a set of background tasks based on
  the `sidekiq` framework for background/asynchronous tasks.
* Changes to the Data and/or Image Storage via the Administrative
  Interface or Image Uploader Interface trigger the domino sync for a
  specific ERICA resource. This puts a corresponding sync job into a
  queue that is processed by an external `sidekiq` process.
* A `sidekiq` management interface is hooked into the Administrative
  Interface, access is limited via the User/Rights Management.
* The domino sync accesses the IBM Domino server via the "IBM Lotus
  Domino Data Service", a REST+JSON API supplied by the IBM Domino
  Server, starting with version 8.5.3 Upgrade Pack 1.
* The domino sync creates two-way references between ERICA resources
  and Domino documents; i.e., ERICA resources contain the Domino UNID
  (unique ID) of their corresponding Domino document, while the Domino
  document contains the ERICA resource ID of the corresponding ERICA
  resource.

## Consequences

n/A

