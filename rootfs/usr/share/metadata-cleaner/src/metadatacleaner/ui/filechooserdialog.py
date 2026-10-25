# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""File chooser dialog."""

from gettext import gettext as _
from gi.repository import Gtk

from metadatacleaner.modules.filestore import SUPPORTED_FORMATS


class FileChooserDialog(Gtk.FileChooserNative):
    """File chooser dialog."""

    __gtype_name__ = "FileChooserDialog"

    def __init__(self, *args, **kwargs) -> None:
        """File chooser dialog initialization."""
        super().__init__(*args, **kwargs)
        self._setup_file_filter()

    def _setup_file_filter(self) -> None:
        file_filter = Gtk.FileFilter()
        file_filter.set_name(_("All supported files"))
        for mimetype, extensions in SUPPORTED_FORMATS.items():
            for extension in extensions:
                file_filter.add_suffix(extension[1:])
        self.add_filter(file_filter)
