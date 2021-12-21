---
date: "2020-05-15"
status: PROPOSAL
number: "0001"
title: Forms and Form Answers
author: Arthur Andersen <aandersen@velalu.qa>
---

# ADR 0001 - Forms and Form Answers

## Glossary

- **CRUD** :: Create, Read, Update, Destroy

## Context

ERICA read introduced the concept of reads. *Sessions* specify a list of *Cases*
which are read by readers on a case-by-case basis. For each *Case* a
*Form* is displayed and the reader client (macos native software) opens
the associated *ImageSeries* via OsiriX (or any DICOM viewer in the future).

The *Form* displays a freely configurable
- previous results

The reader may take and reference measurements, answers the form questions and then signs and
submits the *FormAnswers*. The next case of the session starts right
away if existent.

Sessions and Forms are configured through JSON/YAML files which are
validated through JSONSchemas,
uploaded and versioned. Forms and Sessions can have validation/testing and
production states.

- validation / production
- eigene nutzer
- eigene cases
- eigene viewer session configuration

Sessions types

- normal
  - form input, signature, submit
- adjudication
  - results from other readers are displayed with measurements, annotations and previous history as configured
  - reader selects one of them
  - sign, submit

This ADR discusses a generalized implementation in ERICA SaaS for the
purpose of remote read sessions and advanced technical and medical
quality control, as the existing limited tQC and mQC functionality will be
superceded by a more flexible architecture.




Rolle / User spezifische cases/sessions

1. case keinem nutzer/keiner rolle zugewiesen, jeder kann anfangen,
   aber der der angefangen hat muss es beenden
2. case is spez. nutzer zugew., nur der nutzer kann anfangen, nur der
   nutzer muss beenden
3. case is rolle zugewiesen, jeder nutzer der rolle kann anfangen,
   jeder mit der rolle kann auch weitermachen


Gruppe: Reader, Training:


Visit zu Case Beziehung funktioniert nicht -> Visit type ist nicht 100% case type


**Note:** If the same sessions should be read multiple times by
different readers (to verify results), the session, case list and the
referenced forms have to be copied, which means the admin will have to
make sure that the configuration is the same across all sessions.

<div class="mermaid">
classDiagram
    SessionTemplate --> Session
    Session --> Step
</div>

tQC:

trigger: image series angelegt

create task: "tQC"

create step: "tQC" for that image

---

trigger: visit is ready for mQC

create task: "mQC" associated with the visit

create step: ""

---

workflow definiert:

read:

trigger: case angelegt
condition:

create: task "read"

add step for all cases of type x

case list: patientennr - casetype - images

Use Case

- Workflow Management ::
- Image Reads ::

### Business Processes

`TODO`

### User Stories / User Requirements

- As a reader I want to see a list of sessions, in order to start a session
- As a reader I want to start reading all cases to a session, to complete all necessary cases
  - **Note:** cases may be ordered
  - **Note:** cases may dependent on previous cases (cases must be completed in order)
- As a reader I want to step through each case for a session and see a rich content view configurable per case
  - ... I want to see a PDF and a form side-by-side
  - ... I want to see a DICOM viewer and a form side-by-side
    - ... I want to take measurements in the DICOM viewer as a form answer
    - ... I want to view images from this and/or previous cases
  - ... I want to see a Video and a form side-by-side
- As a reader I want to see a feature-rich form in my web browser
- As a reader I want to input my answers in a rich form view
  - ... I want to see previous results inline
  - ... I want to see live form validations / be informed about invalid form states immediately
  - ... I want to see only fields that are necessary the answers that I provide (dependent form fields)
  - ... I want to choose DICOM measurements as value for certain form inputs
  - ... I want to sign and send my form answers when every input is valid
  - **TODO** All session and form specific configurations from ERICA read session & form configuration

- As an admin I want to CRUD forms and their configurations
  - **Note:** rich form editor or simple json upload
  - FR: configurations are versioned and versions are immutable, each form references a specific version
  - ... I want to upload a new session configuration as JSON
  - ... I want to embed forms into other forms
  - ... I want to configure validations for each form field
  - ... I want to configure dependencies for each form field
- As an admin I want to CRUD sessions and their configurations
  - ... I want to upload a new session configuration as JSON
    - FR: configurations are versioned and versions are immutable:
      - forms reference a specific version
	  - form answers reference a specific version at the time of creation
  - ... I want to configure case type
  - ... I want to configure viewer settings
    - allowed measurements
	- images
	- which reader functionality
    - order of images in screen layout -> fix/flexible
    - etc (**TODO:** )
  - ... I want to assign readers (user) to sessions
  - ... I want to assign readers (user) to cases
  - ... I want to assign readers (role) to sessions
  - ... I want to assign readers (role) to cases
  - ... I want to revisit non-submitted cases and resume the process with unsubmitted previous answers

**Note:**

- "Sessions" may be renamed to "workflows".
- "Cases" may be renamed to "steps".

### Questions

- how does the admin create a workflow specifying the Patient, Step, RequiredSeries, etc?
- how are the results displayed?
- what should be done with the results of workflows?
  - export form answers like in ERICA read
- how are workflows created?
  - depends; either trigger for tQC/mQC or case list upload manually
- how are deadlines reflected?
- how does the history work?

### Functional Specification

- Manage (Create, Read, Update, Destroy) Forms
- Read Form Answers
  - Form Component
  - Workflow Module

### Design Specification

#### Entity Relations and Database Schema

The ERD describes the relations and their relations within the
database. We want to make sure these are usable in most forseen
scenarios.

<div class="mermaid">
erDiagram
    Project ||--o{ Configuration : "defines"
	Project ||--o{ SessionTemplate : "defines"
    Configuration }|--|{ SessionTemplate  : "provides config for"
    Configuration }|--|{ Form : "provides config for"
    SessionTemplate ||--|{ Session : "defines"
	Session ||--|{ Step : "consists of"
    Step ||--|{ WorkflowResource : "linked to"
    Step ||--|{ FormAnswer : has
    Form ||--o{ FormAnswer : "is answered by"
    Form |o--o{ Form: "may consist of"
    FormAnswer }|--|| Configuration : "answered for (at that time)"
	FormAnswer ||--|| PublicKey : "signed via"
	FormAnswer }o--|| User : "signed by"
	User ||--o{ PublicKey : "possesses"
</div>

#### Class Diagram

The class diagram describes the models and their attributes. Relation
properties (column names) are included.

<div class="mermaid">
classDiagram
	Project <-- Configuration
	Project <-- SessionTemplate
	Configuration <-- Form
	Form <.. Configuration
    Configuration <-- SessionTemplate
	Form <-- FormAnswer
	User <-- FormAnswer
	User <-- PublicKey
	PublicKey <-- FormAnswer
    SessionTemplate <-- Session
	SessionTemplate *-- Case
	Session *-- Step
	Case <-- Step
	Step -- WorkflowResource
    WorkflowResource <|-- ImageSeries
    WorkflowResource <|-- Visit
    class Project {
	}
    class User
	class Configuration
	class Form
	class FormAnswer {
		string answers
		string signature
		int user_id
		datetime created_at
		datetime updated_at
	}
	class Step {
		int order
		String resource_type
		int resource_id
	}
	class Case {
		int order
	}
	class SessionTemplate
	class PublicKey
	class WorkflowResource
</div>


#### Functional Components / Dependencies

<div class="mermaid">
classDiagram
    ConfigurationModule <-- WorkflowModule
	DigitalSignatureModule <-- WorkflowModule
    ConfigurationModule <-- FormViewModule
    WorkflowModule *-- FormViewModule
    WorkflowModule *-- ContentViewModule
	ContentViewModule *-- DICOMViewer
	ContentViewModule *-- VideoPlayer
	ContentViewModule *-- PDFViewer
</div>

### Consequences

- tQC functionality will be reimplemented
- mQC functionality will be reimplemented
