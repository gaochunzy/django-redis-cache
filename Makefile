SHELL := /bin/bash
PACKAGE_NAME=redis_cache
SELENIUM_TEST_OUTPUT?=nosetests-selenium.xml

VENV_DIR?=.venv
VENV_ACTIVATE=$(VENV_DIR)/bin/activate
WITH_VENV=. $(VENV_ACTIVATE);


default:
	python setup.py check build

.PHONY: venv setup clean teardown test package shell

$(VENV_ACTIVATE): requirements.txt requirements-dev.txt
	test -f $@ || virtualenv --python=python2.7 --system-site-packages $(VENV_DIR)
	$(WITH_VENV) pip install --no-deps -r requirements.txt
	$(WITH_VENV) pip install -r requirements-dev.txt
	touch $@

venv: $(VENV_ACTIVATE)

setup: venv

tcp_redis_server:
	test -d redis || git clone https://github.com/antirez/redis
	git -C redis checkout 2.6
	make -C redis

redis_servers:
	test -d redis || git clone https://github.com/antirez/redis
	git -C redis checkout 2.6
	make -C redis
	for i in `seq 1 3`; do \
    	./redis/src/redis-server \
    		--pidfile /tmp/redis`echo $$i`.pid \
    		--requirepass yadayada \
    		--daemonize yes \
    		--port `echo 638$$i` \
    done; \

	for i in `seq 4 6`; do \
    	./redis/src/redis-server \
    		--pidfile /tmp/redis`echo $$i`.pid \
    		--requirepass yadayada \
    		--daemonize yes \
    		--port 0 \
    		--unixsocket /tmp/redis`echo $$i`.sock \
    		--unixsocketperm 755 \
    done; \

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
	kill `cat /tmp/redis0.pid`
	kill `cat /tmp/redis1.pid`
	kill `cat /tmp/redis2.pid`
	kill `cat /tmp/redis3.pid`
	kill `cat /tmp/redis4.pid`
	kill `cat /tmp/redis5.pid`

shell: venv
	$(WITH_VENV) PYTHONPATH=$(PYTHONPATH): django-admin.py shell --settings=redis_cache.tests.settings

package:
	python setup.py sdist
