# CHANGELOG

## Unreleased

### Patches / Fixes

* Fix - (ERICA-158) Only allow deletion of empty form sessions
* Fix - (ERICA-154) Fix tracking role permission changes in audit trail

### Dev/DevOps

* Fix - Ensure database is cleaned before testing test data factories

## 7.2.2

### Patches / Fixes

* Fix - #5780 - Fix inconsistent image series form behavior when changing patient or visit, by removing the patient and visit fields
* Fix - #5783 - Remove "Batch assign image series to patient" as we currently do not adjust DICOM metadata automatically
* Fix - #5784 - Remove create permission for image series

## 7.2.1

### Patches / Fixes

* Fix - (ERICA-139) Fix clearing filter on image series view
* Fix - (ERICA-140) Fix requiring comment when tQC answers are set to fail
* Fix - (ERICA-138) Fix restoring form from downloaded form definition json
* Fix - (ERICA-98) Fix by denying downloading private keys of other users
* Fix - (ERICA-141) Fix XML export of resources
* Fix - (ERICA-137) Fix rejecting archive files at image upload
* Fix - (ERICA-136) Fix recognition of mp4 and similar

## 7.2.0

### Minor Changes

* Feature - Allow cleaning DICOM tag values for all images of a whole image series or a whole study (depending on authorization)
* Feature - Display nested DICOM attributes and `SQ` VR accordingly
* Permissions - Manage access to DICOM metadata via the new `read_dicom_metadata` permission for `ImageSeries`
* Change - Use `[name of image series]#[position of image in series]` as new text representation of images (e.g. in image view or audit trail record references)

### DevOps

* Replace `letter_opener` gem by `mailcatcher` docker container to extract mail catching from the Rails application itself
* Remove validation report formatter due to CI errors (Needs to be fixed in next major release)

## 7.1.0

### Minor Changes

* Update Rails to 5.2 and adjust all remaining dependencies
* Enhance navigation button stylesheets by adding hover hinting background color indicating possible interaction and adjusting icon size
* Feature - Form Functionality for basic independant read sessions and single forms
* Feature - Allow uploading any file format (e.g. PDFs, JPEG, etc.)
* Feature - Add react front-end dependencies for future integration of modern single-page application components similar to PDMS
* Feature - Use select2 (enhanced filterable select box component) for all select fields in ERICA
* Feature - Allow notification profiles to trigger for active admin comment events

### Fixed

* Fix string representation of notification profiles
* Fix missing notification profile recipients in select field if a
  study is selected for the current user's browser session
* Fix mimetype recognition after `mimemagic` was relicensed by
  replacing it with `marcel` by the Rails core team
* Fix tracking notification profile and email template changes in audit trail
* Fix link label to scopes (e.g. Center, Study or Patient) in users `UserRole` list
* Fix user exports by not publishing users public/private keys via CSV, JSON or XML
* Fix email template preview in show and edit view of email templates

## 7.0.18

### Fixed

* ([ERICA-25](https://jira.pharmtrace.com/browse/ERICA-25)) Fix
  missing attributes for `RequiredSeriesDrop` and `VisitDrop`

### DevOps

* Ensure a password in CI testing environment for the `postgres` role

## 7.0.17

### Fixed

* ([ERICA-5](https://jira.pharmtrace.com/browse/ERICA-5)) Fix batch
  action permissions for image series assign visit and assign patient
* ([ERICA-11](https://jira.pharmtrace.com/browse/ERICA-11)) Show
  required series in audit trail when filtered by resource
* ([ERICA-12](https://jira.pharmtrace.com/projects/ERICA/issues/ERICA-12))
  Show link to visit for required series in audit trail
* ([ERICA-19](https://jira.pharmtrace.com/projects/ERICA/issues/ERICA-19))
  Fix sort order of required series on show visit page
* ([ERICA-21](https://jira.pharmtrace.com/projects/ERICA/issues/ERICA-21))
  Fix permissions for medical assessment

## 7.0.16

### DevOps

* Pass encrypted password to `erica:seed:root_user`
* Add `erica:helper:generate_encrypted_password` task

## 7.0.15

### Internal

* ([ERICA-10](https://jira.pharmtrace.com/browse/ERICA-10)) Add
  `dry_run` parameter to configuration consolidation operation (this
  helps identifying problematic destructive operations due to
  oversight and can be integrated into the UI later on)

## 7.0.14

### Fixed

* ([ERICA-10](https://jira.pharmtrace.com/browse/ERICA-10)) Fix
  consolidating to `locked` configuration in worker

## 7.0.13

### Fixed

* ([ERICA-10](https://jira.pharmtrace.com/browse/ERICA-10)) Reset
  medical quality control results when a new mQC specification is
  locked for a study

## 7.0.12

### Fixed

* ([ERICA-10](https://jira.pharmtrace.com/browse/ERICA-10)) Fix
  consolidation of visit types, required series and technical qc
  results after locking the study configuration at a specific version
* Fix passing down correct version parameter to retrieve the correct
  study configuration (affects Upload of Study Configuration)

### Patches

* <devops> Display basic database user information upon start up for debugging
* <devops> Add optional `email` and `password` parameters to rake task
  `erica:seed:root_user[:username, :email, :password]`

## 7.0.11

### Fixed

* <DEVOPS> Fix checking availability of PostGres database in `docker-entrypoint.sh`
* <ERICA-9> Fix Image Upload for missing `Series Date` in DICOM files
  by falling back to `ContentDate` or `AquisitionDate`

## 7.0.10

### Fixed

* <ERICA-6> Allow upload of unparsable DICOM files (e.g. for embedded PDF data)

## 7.0.9

### Fixed

* <ERICA-2> Fixed role permission problem for permissions `perform_tqc` and `read_tqc`

### DevOps

* Fix building manual via ubuntu 18.04 LTS docker image
* Use sequence to generate unique e-mail addresses for test users

## 7.0.8

### Fixed

* Fixed anonymization of DICOM patient name via `Patient#name` (Remove `Center#id`)
* Fixed #4445 - "Download Images" does not work for non-*system-wide* role assignment

### DevOps

* Patch #4228 - Integrate Full Test-Suite running real browsers
  * Database configuration via environment variables
  * Gitlab CI pipeline with automatic deployment
  * Extract feature test report for validation purposes
* Patch - Remove import volume from development
* Patch - Default `DISABLE_SPRING=t`
* Update - Update docker environment to Debian Stretch for future compatibility

## 7.0.7

*Patches:*

* Bug - Show full patient name in visit list including center code

*Development:*

* Patch - Fix migrations stalling due to `binding.pry`

## 7.0.6

*Patches:*

* Bug #3877 - Fix width of select boxes in resource forms
* Bug #4028 - Fix filter by study, center or patient in record lists
* Bug #4029 - Fix overlapping selectbox in email template form
* Bug #4030 - Fix EmailTemplate preview via EDGE browser

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
