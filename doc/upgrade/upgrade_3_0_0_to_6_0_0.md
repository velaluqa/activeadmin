# Upgrade from 3.0.0 to 6.0.0

This process may take a long time.

## Configure docker to include `import` volume

Use this example as a hint.

**Remember to change the database name in config/database.yml.dev**

```yaml
postgres:
  image: postgres:9.6
  ports:
    - 5432:5432
  volumes:
    - ./tmp/postgresql_data_3_0_0/9.6/data:/var/lib/postgresql/data
redis:
  image: redis
  ports:
    - 6379:6379
app:
  build: &build .
  command: rails s -b 0.0.0.0 -p 3000
  tty: true
  volumes: &volumes
    - .:/app
    - ./config/database.yml.dev:/app/config/database.yml
    - ./config/erica_remotes.yml.dev:/app/config/erica_remotes.yml
    - ./tmp:/app/tmp
    - ./import/data:/app/data
  ports:
    - 3000:3000
  environment: &environment
    DB_USERNAME: postgres
    DB_PASSWORD:
    TRUSTED_IP: 172.18.0.1
  links: &links
    - postgres
    - redis
    - worker
test:
  build: *build
  command: guard
  tty: true
  volumes: *volumes
  environment:
    <<: *environment
    RAILS_ENV: test
  links:
    - postgres
    - redis
worker:
  build: *build
  command: bundle exec sidekiq
  volumes: *volumes
  environment: *environment
  links:
    - postgres
    - redis
https:
  image: nginx
  ports:
    - 443:443
    - 80:80
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf
    - ./erica.conf:/etc/nginx/conf.d/default.conf
  volumes_from:
    - app:rw
  links:
    - app
```

## Extract data directory

```
cd import
mkdir -p pts028.2017.06.26-01-10.data
tar xfzv pts028.2017.06.26-01-10.data.tar.gz -C pts028.2017.06.26-01-10.data
ln -sf pts028.2017.06.26-01-10.data/data data
```

## Import MongoDB data

```
cd import
mkdir -p pts027.2017.06.26-01-10.dump
tar xfzv pts027.2017.06.26-01-10.dump.tar.gz -C pts027.2017.06.26-01-10.dump
doco up -d mongo
doco exec ericastore_mongo_1 mongorestore /import/pts027.2017.06.26-01-10.dump/
```


## Import PostGreSQL data

```
doco exec ericastore_postgres_1 su postgres -s /bin/bash -c "gunzip -c /import/pts021.2017.06.26-01-10.dump.gz | psql"
```

## Update PostGreSQL from 9.1 to 9.6

```
docker run --rm \
  -v /home/arthur/projects/pharmtrace/erica_store_v2/tmp/postgresql_data_3_0_0/9.1/data:/var/lib/postgresql/9.1/data \
  -v /home/arthur/projects/pharmtrace/erica_store_v2/tmp/postgresql_data_3_0_0/9.6/data:/var/lib/postgresql/9.6/data \
  tianon/postgres-upgrade:9.1-to-9.6
```

## Migrate MongoDB data to PostGres

For this we have some migrations in the `migrate-mongo-data` branch.

```
# Check out the branch
git checkout feature-migrate-mongo

# Run migrations
rake db:migrate

# Fill missing gaps in
rake fill_gaps_in_audit_trail
rake migrate_mongo_patient_data
rake migrate_mongo_visit_data

# Check out develop
git checkout develop

# Migrate to latest rails database structure (quick)
rake db:migrate

# Create study_id refs for versions (~5min)
rake erica:migration:add_missing_version_study_id

# Migrate required series presets
rake erica:migration:migrate_required_series
```
