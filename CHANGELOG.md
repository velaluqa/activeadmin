# CHANGELOG

## 7.0.5

*Patches:*

* Bug #3926 - Domino Sync fails with 400 Bad Request for ABX
* Patch #3927 - Provide more information for RestClient::BadRequest
* Patch #3928 - Wrap `update document` in `perform command` block

## 7.0.4

*Patches:*

* Bug #3921 - Changing Domino URL fails with unreadable error message

## 7.0.3

*Patches:*

* Bug #3910 - Catch connection errors to IBM Notes server

## 7.0.2

*Major Changes:* None

*Minor Changes:* None

*Patches:*

* Bug #3625 - Fix download images bug
* Feature #3626 - Commenting feature tests

*Development:* None

## 7.0.1

*Major Changes:* None

*Minor Changes:* None

*Patches:*

* Bug #3608 - Comment feature is blocked by legacy ERICA Remote flags

*Development:* None

## 7.0.0

*Major Changes:*

* Feature #2000 — MongoDB-to-PostGreSQL migration rake tasks
* Feature #3075 — Extract Required Series into proper relation
    * Reimplemented:
	    * required series assignment
        * technical QC
        * medical QC
        * automatic creation of required series from study config
            * upon visit type assignment
            * upon study configuration change of available visit types or required series
* Refactor — Study Configuration Upload

*Minor Changes:*

* Feature #3089 — Make navigation bar stickable
* Feature #3090 — Do not align user session menu links to the bottom
* Feature #3093 — Lighten status_tags colors
* Feature #2297 — Use formtastic_auto_select2 for better usability

*Patches:*

None

*Development:*

None

## 6.0.3

*Major Changes:* None

*Minor Changes:* None

*Patches:*

* Bug #3625 - Fix download images bug

*Development:* None

## 6.0.2

*Major Changes:* None

*Minor Changes:* None

*Patches:*

* Bug #3608 - Comment feature is blocked by legacy ERICA Remote flags

*Development:* None

## 6.0.1

*Major Changes:* None

*Minor Changes:* None

*Patches:*

* Bug #3592 - Image upload fails for given PET images

*Development:* None

## 6.0.0

*Major Changes:*

* Update — Update to Ruby on Rails 4.3
* Refactor — Remove MongoDB in favor of PostGreSQL JSONB data fields
* Feature #1994 — Implement flexible, role-based permission system
* Feature #2542 — Major desktop user inteface redesign
* Feature #2123 — E-Mail-Management — Users must have e-Mail addresses
* Feature #2117 — Notifications — Manage Notification Profiles to send out notifications when data is modified
* Feature #2208 — E-Mail-Templates for Notifications
* Feature #2270 — User Dashboard
* Feature #1995 — Browser Upload — Upload images directly from within the browser

*Minor Changes:*

* Task #2053 — Refactor Image Storage Interface
* Feature — Ask for signature password if missing
* Feature #2545 — Use sorted select2 elements in forms
* Feature #2619 — Visit Templates

*Patches:*

* Bug #2050 — Fix broken batch action feature
* Bug #2051 — Fix broken advanced filters via select2
* Refactor — Coding style clean up where possible
* Update — Update WEASIS

*Development:*

* Introduced Docker setup for reproducable development environments
