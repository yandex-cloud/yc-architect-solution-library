import os


class Config(object):
    DEBUG = True
    TESTING = False
    DATABASE = {
            'user': os.getenv('DB_USER'),
            'password': os.getenv('DB_PASSWORD'),
            'host': os.getenv('DB_HOST'),
            'port': os.getenv('DB_PORT', 5432),
            'name': os.getenv('DB_NAME')
            }
    SQLALCHEMY_DATABASE_URI = 'postgresql://{}:{}@{}:{}/{}'.format(
            DATABASE['user'],
            DATABASE['password'],
            DATABASE['host'],
            DATABASE['port'],
            DATABASE['name']
            )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SERVICE_ONE = os.getenv('SERVICE_ONE')


class DevelopmentConfig(Config):
    """
    Development environment configuration
    """
    DEBUG = True


class ProductionConfig(Config):
    """
    Production environment configuration
    """
    DEBUG = False
    TESTING = False


app_config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    }
