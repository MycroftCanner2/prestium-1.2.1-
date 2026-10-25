# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Row representing a file."""

from gi.repository import GLib, GObject, Gtk

from metadatacleaner.modules.file import File

from metadatacleaner.ui.badge import Badge


@Gtk.Template(
    resource_path="/fr/romainvigier/MetadataCleaner/ui/FileRow.ui"
)
class FileRow(Gtk.Box):
    """Row representing a file."""

    __gtype_name__ = "FileRow"

    file: File = GObject.Property(type=File)
    position: int = GObject.Property(type=int)

    @Gtk.Template.Callback()
    def _on_remove_file_button_clicked(self, button: Gtk.Button) -> None:
        self.activate_action(
            "win.remove-file",
            GLib.Variant.new_uint32(self.position))

    @Gtk.Template.Callback()
    def _on_file_clicked(self, button: Gtk.Button) -> None:
        self.activate_action(
            "files.select",
            GLib.Variant.new_uint32(self.position))
