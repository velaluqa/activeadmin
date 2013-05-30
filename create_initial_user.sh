#!/bin/bash

bundle exec rails runner -e"$1" "eval(File.read 'create_initial_user.rb')"
