#!/bin/bash

echo "Cleaning migration testing ERICA db"
rake db:drop RAILS_ENV=migration_test
rake db:migrate RAILS_ENV=migration_test

echo "Cleaning migration testing mongo db"
mongo erica_migration_test --eval 'db.dropDatabase()'

echo "Cleaning migration testing image storage"
rm -R /home/profmaad/Workspace/freelance/PharmTrace/Study\ Server-v2/data/migration_images/*

echo "Cleaning migration testing migration db"
rake goodimage_migration:clear_migration_db RAILS_ENV=migration_test MIGRATION_ENV=development

echo "Cleaning migration testing log"
echo -n '' > /home/profmaad/Workspace/freelance/PharmTrace/Study\ Server-v2/log/migration_test.log

echo "All done!"
