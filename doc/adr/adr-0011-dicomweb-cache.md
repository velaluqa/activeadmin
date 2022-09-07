---
date: "2022-06-15"
status: ACCEPTED
number: "0010"
title: DICOMweb as viewer end-point
author: Arthur Andersen <aandersen@velalu.qa>
---

# ADR 0010 - DICOMweb as OHIF Viewer end-point

## Status

`ACCEPTED`

## Glossary

- OV - [OHIF/Viewers](https://github.com/OHIF/Viewers)

## Context

As described in preceding [ADR0010](./adr-0010-dicomweb.md) fetching
dicom metadata and frame data needs to be cached in order to provide
proper performance when the user wants to view dicom images in the
zero-footprint viewer.

Caching

## Decision

### Cache DICOM metadata

DICOM metadata as specified by DICOMweb is cached in the database:

1. Metadata is cached for `Patient`, `ImageSeries` and `Image` models.
2. Each model gets a new column `#cache` of type `JSONB`. This data can be extended for future caching needs.
3. DICOMweb data is cached in `cache -> dicomWebMetadata` and can be fetched as `json_object` with a single SQL select.

### Cache DICOM frame data

DICOM frame data as specified by DICOMweb is cached as binary file in
`[app_data]/cache/dicomWebFrames/[image_id].[frame_number].bin`.

If the file does not exist then this file needs to be created in time.

Otherwise this file is used for the request.

### Caching Hooks

When to update cache:

- patient metadata cache
  - patient change
  - image file change
  - image creation
- image series metadata cache
  - patient change
  - image series change
  - image file change
  - image creation
- image metadata cache
  - patient change
  - image series change
  - image file change
  - image creation
- frame data cache
  - image creation

### Background Job

Caching may be taking a long time, thus caching is performed
asynchronously by a BackgroundJob `DicomWebCacheWorker`.

## Consequences

n/a
