#!/bin/bash

cd ~/material/mkdocs_dev_material
source venv/bin/activate
mkdocs serve --dev-addr 0.0.0.0:8000 --verbose &
