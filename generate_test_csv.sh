#!/usr/bin/env bash

if [ ! -d ./venv ]; then
  python3 -m venv venv
  source venv/bin/activate
  pip install pandas
  pip install shapely
fi
source venv/bin/activate
source .env

python -m generate_test_csv $N_CLIENTS $N_TRANSACTIONS $N_MERCHANTS $FILENAME 

deactivate