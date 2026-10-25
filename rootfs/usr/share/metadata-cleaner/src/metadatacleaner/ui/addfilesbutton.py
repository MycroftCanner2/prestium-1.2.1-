# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Button allowing to add files."""

from gi.repository import Adw, Gtk


@Gtk.Template(
    resource_path="/fr/romainvigier/MetadataCleaner/ui/AddFilesButton.ui"
)
class AddFilesButton(Gtk.Widget):
    """Button allowing to add files."""

    __gtype_name__ = "AddFilesButton"
