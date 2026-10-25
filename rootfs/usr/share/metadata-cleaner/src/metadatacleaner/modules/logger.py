# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Logging facility using GLib."""

import inspect

from gi.repository import GLib, GObject


class Logger(GObject.GObject):
    """Logging facility using GLib."""

    _DOMAIN = "fr.romainvigier.MetadataCleaner"

    @staticmethod
    def _log(message: str, level: GLib.LogLevelFlags) -> None:
        caller_frame = inspect.stack()[2]
        gvariant_dict = GLib.Variant("a{sv}", {
            "MESSAGE": GLib.Variant("s", message),
            "CODE_FILE": GLib.Variant("s", caller_frame.filename),
            "CODE_LINE": GLib.Variant("i", caller_frame.lineno),
            "CODE_FUNC": GLib.Variant("s", caller_frame.function)
        })
        GLib.log_variant(Logger._DOMAIN, level, gvariant_dict)

    @staticmethod
    def debug(message: str) -> None:
        """Print debug message.

        Args:
            message (str): Message to print.
        """
        Logger._log(message, GLib.LogLevelFlags.LEVEL_DEBUG)

    @staticmethod
    def warning(message: str) -> None:
        """Print warning message.

        Args:
            message (str): Message to print.
        """
        Logger._log(message, GLib.LogLevelFlags.LEVEL_WARNING)

    @staticmethod
    def message(message: str) -> None:
        """Print message.

        Args:
            message (str): Message to print.
        """
        Logger._log(message, GLib.LogLevelFlags.LEVEL_MESSAGE)

    @staticmethod
    def error(message: str) -> None:
        """Print error message.

        Args:
            message (str): Message to print.
        """
        Logger._log(message, GLib.LogLevelFlags.LEVEL_ERROR)

    @staticmethod
    def info(message: str) -> None:
        """Print informational message.

        Args:
            message (str): Message to print.
        """
        Logger._log(message, GLib.LogLevelFlags.LEVEL_INFO)

    @staticmethod
    def critical(message: str) -> None:
        """Print critical message.

        Args:
            message (str): Message to print.
        """
        Logger._log(message, GLib.LogLevelFlags.LEVEL_CRITICAL)
