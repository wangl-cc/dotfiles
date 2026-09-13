"""Route package progress to stderr for the lifetime of one CLI invocation."""

import logging
from collections.abc import Iterator
from contextlib import contextmanager


@contextmanager
def progress_output() -> Iterator[None]:
    logger = logging.getLogger("portable_pkgs")
    handler = logging.StreamHandler()
    level, propagate = logger.level, logger.propagate
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    logger.propagate = False
    try:
        yield
    finally:
        logger.removeHandler(handler)
        handler.close()
        logger.setLevel(level)
        logger.propagate = propagate
