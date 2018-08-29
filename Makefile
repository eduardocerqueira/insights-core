#
# Makefile for insight-core
#
# requires: gcc 
# run: make
#

NO_COLOR    = \x1b[0m
OK_COLOR    = \x1b[32;01m
WARN_COLOR  = \x1b[50;01m
ERROR_COLOR = \x1b[31;01m
SHELL = bash
ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# menu actions
help:
	@echo -e "Please use $(WARN_COLOR) \`make <target>\'$(NO_COLOR) where $(WARN_COLOR)<target>$(NO_COLOR) is one of"
	@echo -e "  $(OK_COLOR)--- setup ---$(NO_COLOR)"	
	@echo -e "  $(WARN_COLOR)init$(NO_COLOR)        		to initialize python virtualenv and install pip packages"
	@echo -e "  $(WARN_COLOR)setup-dev$(NO_COLOR)         	to setup your machine to contribute on this project"
	@echo -e "  $(OK_COLOR)--- doc ---$(NO_COLOR)"
	@echo -e "  $(WARN_COLOR)docs$(NO_COLOR)              	to make documentation in the default format"
	@echo -e "  $(OK_COLOR)--- code ---$(NO_COLOR)"
	@echo -e "  $(WARN_COLOR)codecheck$(NO_COLOR)         	to run code check on the entire project"
	@echo -e "  $(OK_COLOR)--- clean ---$(NO_COLOR)"
	@echo -e "  $(WARN_COLOR)clean-doc$(NO_COLOR)        	to remove docs and doc build artifacts"
	@echo -e "  $(WARN_COLOR)clean-cache$(NO_COLOR)       	to clean pytest cache files"
	@echo -e "  $(WARN_COLOR)clean-venv$(NO_COLOR)        	to clean python venv used by insights-tests"
	@echo -e "  $(WARN_COLOR)clean-egg$(NO_COLOR)        	to clean python venv used by insights-tests"
	@echo -e "  $(WARN_COLOR)clean-all$(NO_COLOR)         	to clean cache, pyc, logs and docs"
	@echo -e "  $(OK_COLOR)--- run tests ---$(NO_COLOR)"
	@echo -e "  $(WARN_COLOR)test$(NO_COLOR)            	run all tests for client"
	@echo -e "  $(OK_COLOR)--- egg ---$(NO_COLOR)"
	@echo -e "  $(WARN_COLOR)egg$(NO_COLOR)         		import test-cases to Polarion"
	@echo -e "$(NO_COLOR)"

# initialize virtualenv on default OS python and install pip modules
init: clean-venv
	virtualenv venv; \	
	source venv/bin/activate; \
	pip install --upgrade pip; \
	pip install -e .[develop]; \

# delete python virtualenv folder
clean-venv:
	@rm -rf venv;

docs:
	@test -d venv || $(MAKE) init; \
	source venv/bin/activate; \
	pip install -r docs/requirements.txt; \
	cd docs; pwd; \
	$(MAKE) html; \

docs-clean:
	$(info "Cleaning docs...")
	@cd docs; $(MAKE) clean

codecheck:
	@echo -e "$(WARN_COLOR)----Starting PEP8 code analysis----$(NO_COLOR)"
	find src -path src/tests/satellite -prune -o -name '*.py' -print | xargs pep8 \
	--verbose --statistics --count --config=pep8 --show-pep8 --exclude=.eggs
	@echo

	@if [ "$(python_version_major)" != 2 ] || [ "$(python_version_minor)" != 6 ]; then \
		echo -e "$(WARN_COLOR)----Starting Pylint code analysis----$(NO_COLOR)"; \
		find src -path src/tests/satellite -prune -o -name '*.py' -print | xargs pylint --disable C,R --rcfile=pylintrc; \
		fi

gitflake8:
	$(info "Checking style and syntax errors with flake8 linter...")
	@flake8 $(shell git diff --name-only | grep ".py$$") tests/__init__.py --show-source

clean-cache:
	$(info "Cleaning the .cache directory...")
	rm -rf .cache

clean-all: docs-clean pyc-clean clean-cache

# Special Targets -------------------------------------------------------------
.PHONY: help docs docs-clean lint pyc-clean gitflake8 clean-cache clean-all

clean-pyc: ## remove Python file artifacts
	$(info "Removing unused Python compiled files, caches and ~ backups...")
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

## steps described at http://insights-tests.usersys.redhat.com/contributing.html#dev-env
setup-dev:
	$(MAKE) load-vars
	@echo "installing required packages"
	yum -y install git python-setuptools
	@if [ "${OS_MAJOR_VERSION}" = 7 ]; then curl -O https://bootstrap.pypa.io/get-pip.py; else curl -O https://bootstrap.pypa.io/2.6/get-pip.py; fi
	python get-pip.py
	pip install virtualenv
	@echo
	@echo now you should initialize your python venv running: make init
	@echo
