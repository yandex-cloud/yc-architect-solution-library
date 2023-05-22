from isoduration.parser.exceptions import InvalidFractional
from isoduration.parser.util import is_integer
from isoduration.types import Duration


def validate_fractional(duration: Duration) -> None:
    fractional_allowed = True

    for _, value in reversed(duration):
        if fractional_allowed:
            if not value.is_zero():
                # Fractional values are only allowed in the lowest order
                # non-zero component.
                fractional_allowed = False
        elif not is_integer(value):
            raise InvalidFractional("Only the lowest order component can be fractional")
