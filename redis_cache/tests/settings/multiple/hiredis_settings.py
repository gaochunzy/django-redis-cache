from redis_cache.tests.settings.base_settings import *


CACHES = {
    'default': {
        'BACKEND': 'redis_cache.cache.ShardedRedisCache',
        'LOCATION': [
            '127.0.0.1:6380',
            '127.0.0.1:6381',
            '127.0.0.1:6382',
        ],
        'OPTIONS': {
            'DB': 15,
            'PASSWORD': 'yadayada',
            'PARSER_CLASS': 'redis.connection.HiredisParser',
            'PICKLE_VERSION': 2,
            'CONNECTION_POOL_CLASS': 'redis.ConnectionPool',
            'CONNECTION_POOL_CLASS_KWARGS': {
                'max_connections': 2,
            }
        },
    },
}

import redis

ports = [6380, 6381, 6382]
for port in ports:
    client = redis.Redis(db=15, port=port)
    try:
        client.config_set('requirepass', 'yadayada')
    except redis.exceptions.ResponseError:
        pass


