# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Folder chooser dialog."""

from gettext import gettext as _
from gi.repository import Gtk


class FolderChooserDialog(Gtk.FileChooserNative):
    """Folder chooser dialog."""

    __gtype_name__ = "FolderChooserDialog"

    def __init__(self, *args, **kwargs) -> None:
        """Folder chooser dialog initialization."""
        super().__init__(*args, **kwargs)
        self._setup_choice()

    def _setup_choice(self) -> None:
        self.add_choice(
            "recursive", _("Add files from subfolders"), None, None)
        self.set_choice("recursive", "true")
