# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Row displaying a metadata."""

from gi.repository import GObject, Gtk


@Gtk.Template(
    resource_path="/fr/romainvigier/MetadataCleaner/ui/MetadataDetailsRow.ui"
)
class MetadataDetailsRow(Gtk.ListBoxRow):
    """Row displaying a metadata."""

    __gtype_name__ = "MetadataDetailsRow"

    key = GObject.Property(type=str, default="")
    value = GObject.Property(type=str, default="")
