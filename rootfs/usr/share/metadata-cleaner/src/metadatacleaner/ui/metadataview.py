# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""List of multiple files' metadata."""

from gi.repository import GObject, Gtk

from metadatacleaner.modules.metadata import MetadataStore
from metadatacleaner.ui.metadatadetails import MetadataDetails


@Gtk.Template(
    resource_path="/fr/romainvigier/MetadataCleaner/ui/MetadataView.ui"
)
class MetadataView(Gtk.ScrolledWindow):
    """List of multiple files' metadata."""

    __gtype_name__ = "MetadataView"

    metadata = GObject.Property(type=MetadataStore)
