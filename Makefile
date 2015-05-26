SHELL := /bin/bash
PACKAGE_NAME=redis_cache

VENV_DIR?=.venv
VENV_ACTIVATE=$(VENV_DIR)/bin/activate
WITH_VENV=. $(VENV_ACTIVATE);


default:
	python setup.py check build

.PHONY: venv setup clean teardown test package shell

$(VENV_ACTIVATE): requirements*.txt
	test -f $@ || virtualenv --python=python2.7 --system-site-packages $(VENV_DIR)
	$(WITH_VENV) pip install --no-deps -r requirements.txt
	$(WITH_VENV) pip install -r requirements-dev.txt
	$(WITH_VENV) $(test -f requirements-local.txt && pip install -r requirements-local.txt)
	touch $@

venv: $(VENV_ACTIVATE)

setup: venv

redis_servers:
	test -d redis || git clone https://github.com/antirez/redis
	git -C redis checkout 2.6
	make -C redis
	for i in 1 2 3; do \
    	./redis/src/redis-server \
    		--pidfile /tmp/redis`echo $$i`.pid \
    		--requirepass yadayada \
    		--daemonize yes \
    		--port `echo 638$$i` ; \
    	done

	for i in 4 5 6; do \
    	./redis/src/redis-server \
    		--pidfile /tmp/redis`echo $$i`.pid \
    		--requirepass yadayada \
    		--daemonize yes \
    		--port 0 \
    		--unixsocket /tmp/redis`echo $$i`.sock \
    		--unixsocketperm 755 ; \
    	done
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

test: venv redis_servers
	$(WITH_VENV) PYTHONPATH=$(PYTHONPATH): django-admin.py test --settings=redis_cache.tests.settings
	for i in 1 2 3 4 5 6; do \
		kill `cat /tmp/redis$$i.pid` \
	done

shell: venv
	$(WITH_VENV) PYTHONPATH=$(PYTHONPATH): django-admin.py shell --settings=redis_cache.tests.settings

package:
	python setup.py sdist
