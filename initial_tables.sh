#!/usr/bin/env bash


psql -U ${POSTGRES_USER} -v db_name=${POSTGRES_DB} -tc "SELECT 1 FROM pg_database WHERE datname = :'db_name'" | grep -q 1 || psql -U ${POSTGRES_USER} -c "CREATE DATABASE :'db_name'"
