## Study Configuration

The configuration is done via uploading configuration files to a
specific study. These configuration files are written in YAML format,
which is a human-readable data serialization language.

You can find a comprehensive documentation of the YAML language here:

http://www.yaml.org/spec/1.2/spec.html

### Configuration Section

The study configuration requires four specific configuration sections:

```yaml
visit_types: {}
visit_templates: {}
image_series_properties: []
domino_integration: {}
```

#### Visit Types

TODO

#### Visit Templates

The section `visit_templates` is a key-value map defining all available visit templates:

```yaml
visit_templates:
  default: <<Template Options>>
```

##### Template Options

- `label` (_optional_, string) — A string representation that is shown to the user.
- `repeatable` (_optional_, bool, _default: no_) — This visit template can be used repeatedly to create the same set of visits.
- `create_patient_default: yes/no` (_optional_, bool, _default: no_) — This visit template is preselected in the create patient form. A user may deselect the template and proceed creating a patient without predefined visits.
- `hide_on_create_patient: yes/no` (_optional_, bool, _default: no_) — This visit template is hidden in the create patient form, it is only shown in the create visits from template form after a patient was created.
- `only_on_create_patient: yes/no` (_optional_, bool, _default: no_) — This visit template is only shown in the create patient from. Otherwise it is hidden.
- `create_patient_enforce: yes/no` (_optional_, bool, _default: no_) — This visit template is enforced when creating a patient. _Note: This option overrides `create_patient_default`, `hide_on_create_patient` and the users permissions to `create_from_template`. If this option is `true`, the visit template will be enforced whenever a patient is created.
- `visits` (_required_, sequence) — Set of visits that are created with this visit template.

##### Visit Definitions

Multiple visits can be defined for a visit template:

- `number` (_integer_, required) — The unique visit number that is created by the visit template.
- `type` (_string_, required) — Reference to the visit type of the visit that should be created by this visit template.
- `description` (_string_, optional) — A description for the new visit.

See:

```yaml
visit_templates:
  default:
	label: 'My beautiful visit template'
    visits:
	  - number: 1
	    type: baseline
		description: 'Some optional description'
```

##### Example #1

```yaml
visit_templates:
  default:
    # This template is enforced when creating a patient.
	create_patient_enforce: yes
	# Further usage of this template is disabled.
	only_on_create_patient: yes
    visits:
	  - number: 1
	    type: baseline
		description: 'Initial visit'
	  - number: 2
	    type: baseline
		description: 'Some optional description'
```

##### Example #2

```yaml
visit_templates:
  default:
	label: 'My beautiful visit template'
    # This template is enforced when creating a patient.
	create_patient_enforce: yes
	# Further usage of this template is disabled
	only_on_create_patient: yes
    visits:
	  - number: 1
	    type: baseline
		description: 'Initial visit'
	  - number: 2
	    type: baseline
		description: 'Some optional description'
  repetition:
	label: 'My beautiful visit template'
	visits:
	  - number: 1
	    type: baseline
		description: 'Repeated visit'
```

##### Example #3

```yaml
visit_templates:
  default:
	label: 'My beautiful visit template'
    # This template is selected by default when creating a patient.
	create_patient_default: yes
    visits:
	  - number: 1
	    type: baseline
		description: 'Initial visit'
	  - number: 2
	    type: baseline
		description: 'Some optional description'
  additional:
    # Only allow this template after a patient was created.
    hide_on_create_patient: yes
    visits:
	  - number: 3
	    type: baseline
		description: 'Additional visit'
```

#### Image Series Properties

TODO

#### Domino Integration

TODO
