# ADR - Postgresql As Datastore

## Status

`ACCEPTED`

## Context

A complex application as the Pharmtrace DMS needs a reliable database
management system for storing data. In the past Lotus Domino document
database was used. We realized that missing normalization, schema
structure and migration features led to poor consistency of the data.
Thus, high consistency and reliability should be the most important
requirement.

Further business priorities:

- High consistency of stored data
- Minimize costs of additional training
- Supports development to meet software requirements
    - Extensibility for additional behavior
    - Structured, typed data to ensure consistency on the database level
    - Occasional free-form data types for certain data entries
    - Descriptive, explorable schema

There are different solutions one might choose from:

- Document-oriented databases (NoSQL; e.g. MongoDB)
- Relational Database Management Systems (RDBMS; e.g. MySQL, PostgreSQL)
- Graph Databases (GDB; )

Graph databases are new to the software stack at Pharmtrace. To limit
the need for additional training we ruled them out. Document databases
are similar to the Domino database. Validation and consistency-checks
would have to be performed mainly by the application layer. RDBMS
allow to define relational schemas which normalize the data and ensure
consistency across relations.

## Decision

We use PostgreSQL as main relational database management system. As it
is already used by other Pharmtrace software products we *avoid
introducing a completely new technology* for that a new developer
would have to be trained. Further the relational schema helps us to
ensure *strong consistency of the data* making sure that we do not
arrive at a state of missing associations, wrong value types, etc.
Still via JSONB we can store *free-form JSON data* in the database.
There are means to validate JSONB column data either in the database
itself or on the application layer, which provides either rigid (think
of schema structure) and flexible consistency checks.
Further PostgreSQL is supported by Active Record (Ruby on Rails).
To make the schema and database structure explorable we can render
ER-diagrams from the schema and add comments to tables, columns and
functions.

## Consequences

- Schema should be managed by migrations (this is part of Rails).
- Access to the Data Storage is only possible via the model layer of
  the Ruby on Rails web application
   - data is validated by schema constraints (e.g. `NOT NULL`, column
     types, unique indexes, etc.).
- The model layer uses the `pg` ruby gem to access the PostgreSQL
  server and the `sidekiq` gem, which handles all communication with
  the Redis server.
- Access by users is organized via the other ERICA components
  (Administrative Interface)
