# ADR - Image Storage

## Status

`ACCEPTED`

## Context

ERICA SaaS needs to manage images according to a hierarchy of studies,
centers, patients, visits. Images collected are DICOM files.

## Decision

Upon upload files are stored in the specified hierarchy. As an image
series might not be assigned to a visit yet, it is stored in:

- study ID
   - center ID
      - patient ID
	     - "_unassigned"
		
Once images are assigned to a visit, the images are moved from
"_unassigned" to the respective visit folder:

- study ID
   - center ID
      - patient ID
	     - visit ID

## Consequences

The image storage needs to be protected from outside changes that
would cause inconsistencies between the database and the file system.
Image storage is only to be manipulated from within ERICA SaaS.
