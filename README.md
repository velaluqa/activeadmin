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

All ruby dependencies are listed in `Gemfile.lock`.

## Setup

### Install Master Key

The master key is important for encrypting and decrypting the
application's `config/credentials.yml.enc` file.

Usually you want to install the projects master key. Ask your
colleagues where to get the master key from and install it to
`./config/master.key`.

For further information regarding the Rails master key, [see the
magnificent Rails
Guides](https://edgeguides.rubyonrails.org/security.html#environmental-security).

### Build containers

Now build the containers properly.

    docker-compose build

### Preparing Development Database

Before we can run our development server, we need to bootstrap the
databases for the `development` environment.

First we create the database and migrate to a vanilla ERICA database
structure.

    docker-compose run worker rake db:create db:migrate

Then we seed the default roles and the root user for the `development`
environment:

    docker-compose run worker rake erica:seed:root_user[root] erica:seed:roles

## Running Development Server

To run the dev server you have to forward the port:

    docker-compose run -p 3000:3000 app

This starts the Rails server.

## Running Tests

Tests use FactoryBot for ad-hoc test data. This way we ensure our
tests to operate on predictable test data.

First create the database and migrate, similar to the development
environment:

    docker-compose run test rake db:create db:migrate

Then start the test runner via:

    docker-compose run test

### Running specific tests

To run a specific feature test file do so via:

    docker-compose run test rspec <path to file>

For example you can run `spec/features/authentication/login.feature` specifically:

    docker-compose run test rspec spec/features/authentication/login.feature

The same applies to any other RSpec file. To run a specific spec file do so via:

    docker-compose run test rspec <path to file>.

E.g.

    docker-compose run test rspec spec/models/user_spec.rb.

## Test parallelization

We use Knapsack gem (https://github.com/KnapsackPro/knapsack) to run tests in parallel on the CI. To do this effectively it's essentially required that the following is done:

    - Generate a JSON report file (knapsack_rspec_report.json). This file contains the time taken to run all available rspec examples in seconds.
      you can generate this file by running the command below. this can be done locally (for testing purposes), but more importantly on
      the CI as the objective is to split the test running time across a few parallel nodes on the CI.

    docker-compose run -e KNAPSACK_GENERATE_REPORT=true test rspec spec

    - Re-generate the JSON report file whenever changes are made in terms of new step definitions,
      addition of new test files etc. the essence is to have an updated report file.
    
### Cleaning the database

Rarely the database cleaning while running your tests in Guard fails. This leaves the database in a state that makes tests fail (either due to taken unique keys residing in the database or because results do not match the expectations).

To solve that you can drop the database and recreate it:

    docker-compose run test rake db:drop db:create db:migrate

## Running Bundle Commands

When a new gem is installed, it might be essential to rebuild
containers for changes to take effect.

After adding Gems to your `Gemfile` you need to lock the bundle:

    docker-compose run app bundle lock
	
This will generate the `Gemfile.lock` file.

Then you can rebuild your containers:

    docker-compose build app worker webpack

If you had containers running you should recreate all your containers
by stopping and removing them first. For that you can use
`docker-compose down`:

    docker-compose down

## Running Rails console

To start the rails console do so via:

    docker-compose run app rails console.

To start the irb shell do so via:

    docker-compose run app irb

## Running Rake Tasks

To run rake tasks you have to do it in the docker environment like so:

    docker-compose run app rake <task>

For example printing all routes available use `rake routes`:

    docker-compose run app rake routes

## Write Turnip step definitions

For validation we create a report describing the actions performed to
test a specific feature along with screenshots as proof that these
actions were actually tested.
  
The validation report requires a few things:

### High-level steps reusing existing step definitions

The feature test may profit from combining a verbose set of smaller
steps into higher-level steps that describe e.g. the user interactions
or expectation in a more concise way.

For example:

```feature
Given a user "confirmed.user"
When I browse to the login page
And I fill in "Username" with "confirmed.user"
And I fill in "Password" with "wrong password"
And I click "Sign in"
And I fill in "Username" with "confirmed.user"
And I fill in "Password" with "wrong password"
And I click "Sign in"
And I fill in "Username" with "confirmed.user"
And I fill in "Password" with "wrong password"
And I click "Sign in"
Then I see "Your account is locked"
```

Could be written as:

```feature
When I browse to the login page
And I try to sign in as "confirmed.user" 3 times with incorrect password "any.password"
```

```rb
step 'I try to sign in as :string :count times with incorrect password :string' do |username, count, password|
  count.times do
    step("I fill in \"Username\" with \"#{username}\"")
    step("I fill in \"Password\" with \"#{password}\"")
    step('I click "Sign in"')
  end
end
```

* Do not use `send` in your step definitions to call subsequent steps,
  use `step` instead (and provide a string parameter) to make them
  appear as a substep in the validation report.
  
### Create screenshots
 
In order to generate screenshots for each step call
`validation_report_screenshot` where appropriate.

Typically you would want to take a screenshot when:

- after changing something on the page (e.g. `When I fill in "Input
  Field" with "Some text typed into the input box"`)
- performing an expectation on the page (e.g. `Then I see "My peculiar
  text"`, testing that some text is displayed on the page. The
  screenshot is taken after the Capybara expectation for it to scroll
  the respective text into view.)

### Debugging feature scenarios

You have different possibilities to hook into your code. Generally you
can run a debugger:

- in the feature scenario itself by adding `When I debug`. This will
  start the debugger REPL in its own step
- in the code segment (e.g. in you controller action method run
  `debugger`). This way you will have access to the variables and
  database state at that specific location.
  
Frequent scenarios:

**I cannot see what I expect!**

- Did you setup the database correctly? 
- What is inside the database?
- Are you accessing the right data?

Use the debugger and run your ActiveRecord queries by hand, is the
data correct?

# Upgrade instructions

- [Upgrade 3.0.0 to 6.0.0](./doc/)
