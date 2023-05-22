"""
Exception
 +- ValueError
 |   +- DurationParsingException
 |   |   +- EmptyDuration
 |   |   +- IncorrectDesignator
 |   |   +- NoTime
 |   |   +- UnknownToken
 |   |   +- UnparseableValue
 |   |   +- InvalidFractional
 +- KeyError
     +- OutOfDesignators
"""


class DurationParsingException(ValueError):
    ...


class EmptyDuration(DurationParsingException):
    ...


class IncorrectDesignator(DurationParsingException):
    ...


class NoTime(DurationParsingException):
    ...


class UnknownToken(DurationParsingException):
    ...


class UnparseableValue(DurationParsingException):
    ...


class InvalidFractional(DurationParsingException):
    ...


class OutOfDesignators(KeyError):
    ...
