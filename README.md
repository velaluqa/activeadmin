# ERICA

This document describes all the steps necessary to get this project up
and running for development. A separate manual on how to install this
software in production is deployed with each release.

## Dependencies

The basic dependency to start developing is just Docker and Docker
Compose. It will run all database backend processes (e.g. PostGreSQL,
MongoDB, Redis).

Make sure the following versions are installed on your development
machine:

-   Docker (`> 1.10.3`)
-   Docker Compose (`> 1.6.2`)

Now build the containers properly.

    docker-compose build

## Running Development Server

Before we can run our development server, we need to bootstrap the
databases for the `development` environment.

First we create the database and migrate to a vanilla ERICA database
structure.

    docker-compose run app rake db:create db:migrate

Then we seed the default roles and the root user for the `development`
environment:

    docker-compose run app rake erica:seed:root_user[root] erica:seed:roles

To run the dev server you have to forward the port:

    docker-compose run -p 3000:3000 app

This starts the Rails server.

## Running Tests

Tests use FactoryGirl for ad-hoc test data. This way we ensure our
tests to operate on predictable test data.

First create the database and migrate, similar to the development
environment:

    docker-compose run test rake db:create db:migrate

Then start the test runner via:

    docker-compose run test

## Running Rake Tasks

To run rake tasks you have to do it in the docker environment like so:

    docker-compose run app rake <task>
