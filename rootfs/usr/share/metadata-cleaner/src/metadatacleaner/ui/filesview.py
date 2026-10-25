# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""View showing all the files."""

from gi.repository import Gio, GLib, GObject, Gtk

from metadatacleaner.modules.filestore import FileStore

from metadatacleaner.ui.cleanmetadatabutton import CleanMetadataButton
from metadatacleaner.ui.filerow import FileRow
from metadatacleaner.ui.settingsbutton import SettingsButton
from metadatacleaner.ui.statusindicator import StatusIndicator


@Gtk.Template(resource_path="/fr/romainvigier/MetadataCleaner/ui/FilesView.ui")
class FilesView(Gtk.Box):
    """View showing all the files."""

    __gtype_name__ = "FilesView"

    file_store = GObject.Property(type=FileStore, nick="file-store")

    _selection_model: Gtk.SingleSelection = Gtk.Template.Child()

    def __init__(self, *args, **kwargs) -> None:
        """View initialization."""
        super().__init__(*args, **kwargs)
        self._setup_actions()

    def _setup_actions(self) -> None:
        group = Gio.SimpleActionGroup.new()
        self.insert_action_group("files", group)

        def on_select(action: Gio.Action, parameters: GLib.Variant) -> None:
            self._selection_model.set_selected(parameters.get_uint32())
        select = Gio.SimpleAction.new("select", GLib.VariantType.new("u"))
        select.connect("activate", on_select)
        group.insert(select)

    @Gtk.Template.Callback()
    def _on_selection_changed(
            self,
            selection_model: Gtk.SelectionModel,
            position: int,
            n_items: int) -> None:
        number_of_items = len(selection_model.get_model())
        if selection_model.get_selected() >= number_of_items:
            return
        self.activate_action(
            "win.view-details",
            GLib.Variant.new_uint32(selection_model.get_selected()))

    def get_selected_file_index(self) -> int:
        """Get the index of the currently selected file.

        Returns:
            int: Index of the selected file.
        """
        return self._selection_model.get_selected()

    def clear_selected_file(self) -> None:
        """Unselect the currently selected file."""
        number_of_items = len(self._selection_model.get_model())
        if self._selection_model.get_selected() >= number_of_items:
            return
        self._selection_model.unselect_item(
            self._selection_model.get_selected())
