# ADR - Weasis DICOM Viewer

## Status

`ACCEPTED`

## Context

DICOM files should be viewable by the ERICA user.

## Decision

- Image Series and Patients can be selected for viewing, by adding
  them to the "Viewer Cart"
- Viewing opens an open-source Weasis DICOM Viewer via Java Web Start
- Images are loaded via WADO interface which authenticates and
  authorizes the user via an authorization token passed via Java Web
  Start

## Consequences

- Java & Java Web Start as a dependency
