# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Button to clean metadata of all added files."""

from gi.repository import Gtk


@Gtk.Template(
    resource_path="/fr/romainvigier/MetadataCleaner/ui/CleanMetadataButton.ui"
)
class CleanMetadataButton(Gtk.Button):
    """Button to clean metadata of all added files."""

    __gtype_name__ = "CleanMetadataButton"
