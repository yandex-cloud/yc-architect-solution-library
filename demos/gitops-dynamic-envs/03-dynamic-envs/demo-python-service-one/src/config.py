import os


class Config(object):
    DEBUG = True
    TESTING = False
    APP_VERSION = os.getenv('APP_VERSION')


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
