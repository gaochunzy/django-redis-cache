PACKAGE_NAME=redis_cache
SELENIUM_TEST_OUTPUT?=nosetests-selenium.xml


VENV_DIR?=.venv
VENV_ACTIVATE=$(VENV_DIR)/bin/activate
WITH_VENV=. $(VENV_ACTIVATE);

default:
	python setup.py check build

.PHONY: venv setup clean teardown test package

$(VENV_ACTIVATE): requirements.txt requirements-dev.txt
	test -f $@ || virtualenv --python=python2.7 --system-site-packages $(VENV_DIR)
	$(WITH_VENV) pip install --no-deps -r requirements.txt
	$(WITH_VENV) pip install -r requirements-dev.txt
	touch $@

venv: $(VENV_ACTIVATE)

setup: venv

clean:
	python setup.py clean
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg*/
	rm -rf __pycache__/
	rm -f MANIFEST
	rm -f test.db
	find $(PACKAGE_NAME) -type f -name '*.pyc' -delete

teardown:
	rm -rf $(VENV_DIR)/

test: venv
	$(WITH_VENV) PYTHONPATH=$(PYTHONPATH): django-admin.py test --settings=redis_cache.tests.settings.multiple.hiredis_settings

package:
	python setup.py sdist
