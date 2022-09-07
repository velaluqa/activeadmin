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

In order to display DICOM images within ERICA we need to choose a
Web2.0 viewer component. At the time of writing/implementation the
most advanced web viewer available is the
[OHIF/Viewers](https://github.com/OHIF/Viewers) project. Licensed
under MIT License, it is allowed to integrate this component in
proprietary software projects as ERICA.

OV is able to query and retrieve data from DICOMweb back-ends.

This DICOMweb back-end must provide the following end-points:

- `qido-rs` for querying available DICOM data (see [DICOM
  Standard](https://www.dicomstandard.org/using/dicomweb/query-qido-rs/))
- `wado-rs` for retrieving the image data (see [DICOM
  Standard](https://www.dicomstandard.org/using/dicomweb/retrieve-wado-rs-and-wado-uri/))

## Decision

Each resource that can be accessed via OV must be provided with a
`qido` and `wado` end-point. For more information look at the [DICOM
Standard](https://www.dicomstandard.org/using/dicomweb/).

For example when opening the viewer for an image series the viewer
queries from `/image_series/:id/qido` and retrieves the data from
`/image_series/:id/wado`.

The viewer will then be loaded via `/admin/image_series/:id/viewer`.

Respectively each entrypoint for the viewer needs these end-points:

### Necessary End-points

#### Image Series

Per default the image series is opened on the show image series page
via the following end-points:

- viewer: `/admin/image_series/:id/viewer`
- wado: `/dicomweb/image_series/:id/rs`
- qido: `/dicomweb/image_series/:id/rs`

#### Visits

For accessing the viewer for all the required series of a visit:

- viewer: `/admin/visits/:id/viewer`
- wado: `/dicomweb/visits/:id/rs`
- qido: `/dicomweb/visits/:id/rs`

For accessing the viewer for a specific required series of a visit:

- viewer: `/admin/visits/:id/required_series/:name/viewer`
- wado: `/dicomweb/required_series/:id/rs`
- qido: `/dicomweb/required_series/:id/rs`

#### Viewer Cart

The viewer cart allows to collect resources within the system that are
associated with images and open all of these images in a single viewer
session.

For that we provide the following end-points:

- viewer: `/admin/viewer_cart/viewer`
- wado: `/dicomweb/viewer_cart/rs`
- qido: `/dicomweb/viewer_cart/rs`

### Routes

DICOMweb specfies the following routes:

#### QIDORS

- `GET {s}/studies?...` - Query for studies
- `GET {s}/studies/{study}/series?...` - Query for series in a study
- `GET {s}/studies/{study}/series/{series}/instances?...` - Query for instances in a series

#### WADORS

Only a subset of the routes for WADORS are implemented, as they are
not strictly necessary for OV:

- `GET {s}/studies/{study}` - Retrieve entire study
- `GET {s}/studies/{study}/series/{series}` - Retrieve entire series
- `GET {s}/studies/{study}/series/{series}/metadata` - Retrieve series metadata
- `GET {s}/studies/{study}/series/{series}/instances/{instance}` - Retrieve instance
- `GET {s}/studies/{study}/series/{series}/instances/{instance}/metadata` - Retrieve instance metadata
- `GET {s}/studies/{study}/series/{series}/instances/{instance}/frames/{frames}` - Retrieve frames in an instance
- `GET {s}/{bulkdataURIReference}` - Retrieve bulk data

Not to be implemented:

- `GET {s}/studies/{study}/rendered` - Retrieve rendered study
- `GET {s}/studies/{study}/series/{series}/rendered` - Retrieve rendered series
- `GET {s}/studies/{study}/series/{series}/instances/{instance}/rendered` - Retrieve rendered instance

#### Rails routes

To accomodate the end-points we setup custom routing to the
`DicomwebController` which handles all requests:

```ruby

```

## Consequences

### Cache DICOM metadata

DICOM information must be cached in the database for fast querying
and retrieval.

DICOMweb specifies properties that must be sent with each query or
retrieval request. In order to avoid reading the DICOM files upon each
request, this data is cached in the database as an indexed `JSONB`
column.

This cache needs to be updated automatically, when the underlying
DICOM files change.

Currently ERICA does not rely on a central API for DICOM storage
changes. Thus any situation a file changes must be handled with care.

Basic caching for dicomweb is described in [ADR0011](./adr-0011-dicomweb-cache.md).
