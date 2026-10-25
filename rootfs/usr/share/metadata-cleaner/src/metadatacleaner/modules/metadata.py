# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Metadata classes."""

from gi.repository import Gio, GObject


class Metadata(GObject.GObject):
    """Metadata object."""

    __gtype_name__ = "Metadata"

    key = GObject.Property(type=str)
    value = GObject.Property(type=str)


class MetadataList(Gio.ListStore):
    """Metadata List object."""

    __gtype_name__ = "MetadataList"

    def __init__(self, *args, **kwargs) -> None:
        """Metadata List initialization."""
        Gio.ListStore.__init__(self, item_type=Metadata)


class MetadataFile(GObject.GObject):
    """Metadata File object."""

    __gtype_name__ = "MetadataFile"

    filename = GObject.Property(type=str)
    metadata = GObject.Property(type=MetadataList)


class MetadataStore(Gio.ListStore):
    """Metadata Store object."""

    __gtype_name__ = "MetadataStore"

    def __init__(self, *args, **kwargs) -> None:
        """Metadata Store initialization."""
        Gio.ListStore.__init__(self, item_type=MetadataFile)
