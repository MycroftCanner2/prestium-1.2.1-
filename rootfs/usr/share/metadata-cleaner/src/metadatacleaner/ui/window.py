# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Application window of Metadata Cleaner."""

from gettext import gettext as _
from gi.repository import Adw, Gdk, Gio, GLib, GObject, Gtk
from typing import Any

from metadatacleaner.modules.filestore import FileStore, FileStoreState

from metadatacleaner.ui.addfilesbutton import AddFilesButton
from metadatacleaner.ui.emptyview import EmptyView
from metadatacleaner.ui.filechooserdialog import FileChooserDialog
from metadatacleaner.ui.filesview import FilesView
from metadatacleaner.ui.folderchooserdialog import FolderChooserDialog
from metadatacleaner.ui.menubutton import MenuButton
from metadatacleaner.ui.detailsview import DetailsView
from metadatacleaner.ui.cleaningwarningdialog import CleaningWarningDialog


@Gtk.Template(resource_path="/fr/romainvigier/MetadataCleaner/ui/Window.ui")
class Window(Adw.ApplicationWindow):
    """Application window of Metadata Cleaner."""

    __gtype_name__ = "Window"

    file_store = GObject.Property(type=FileStore, nick="file-store")

    _mode_flap: Adw.Flap = Gtk.Template.Child()
    _view_stack: Gtk.Stack = Gtk.Template.Child()
    _details_view: DetailsView = Gtk.Template.Child()

    _about_window: Adw.AboutWindow = Gtk.Template.Child()
    _file_chooser_dialog: FileChooserDialog = Gtk.Template.Child()
    _folder_chooser_dialog: FolderChooserDialog = Gtk.Template.Child()
    _cleaning_warning_dialog: CleaningWarningDialog = Gtk.Template.Child()

    def __init__(
        self,
        *args,
        **kwargs
    ) -> None:
        """Window initialization."""
        app = kwargs["application"]
        super().__init__(
            title=app.name,
            *args,
            **kwargs
        )
        self._setup_size()
        self._setup_devel_style()
        self._setup_file_store()
        self._setup_about_window()
        self._setup_drop_target()
        self._setup_actions()

    # SETUP #

    def _setup_size(self) -> None:
        def on_close_request(window: Gtk.Window) -> None:
            width, height = self.get_default_size()
            maximized = self.is_maximized()
            self.get_application().settings.set_uint("window-width", width)
            self.get_application().settings.set_uint("window-height", height)
            self.get_application().settings.set_boolean(
                "window-maximized", maximized)
        self.set_default_size(
            self.get_application().settings.get_uint("window-width"),
            self.get_application().settings.get_uint("window-height"))
        if self.get_application().settings.get_boolean("window-maximized"):
            self.maximize()
        self.connect("close-request", on_close_request)

    def _setup_devel_style(self) -> None:
        if self.get_application().devel:
            self.add_css_class("devel")

    def _setup_file_store(self) -> None:

        def on_items_changed(
                file_store: FileStore,
                position: int,
                added: int,
                removed: int) -> None:
            if len(file_store) == 0:
                self.lookup_action("clean-metadata").set_enabled(False)
                self.close_details_view()
                self.show_empty_view()
            else:
                self.show_files_view()

        def on_state_changed(
                file_store: FileStore,
                file_index: int) -> None:
            self.lookup_action("clean-metadata").set_enabled(not (
                file_store.state == FileStoreState.WORKING
                or len(file_store.get_cleanable_files()) == 0))

        self.file_store = FileStore()
        self.file_store.connect("items-changed", on_items_changed)
        self.file_store.connect("file-state-changed", on_state_changed)
        self.file_store.connect("state-changed", on_state_changed)
        self.get_application().settings.bind(
            "lightweight-cleaning",
            self.file_store,
            "lightweight-mode",
            Gio.SettingsBindFlags.DEFAULT)

    def _setup_about_window(self) -> None:
        self._about_window.add_acknowledgement_section(
            _("Libraries"), ["mat2 https://0xacab.org/jvoisin/mat2"])

    def _setup_drop_target(self) -> None:

        def on_drop(
                widget: Gtk.DropTarget,
                value: Any,
                x: int,
                y: int):
            if isinstance(value, Gdk.FileList):
                self.file_store.add_gfiles(value.get_files())

        drop_target = Gtk.DropTarget.new(Gdk.FileList, Gdk.DragAction.COPY)
        drop_target.connect("drop", on_drop)
        self.add_controller(drop_target)

    def _setup_actions(self) -> None:

        def on_close(action: Gio.Action, parameters: None) -> None:
            self.destroy()
        close = Gio.SimpleAction.new("close", None)
        close.connect("activate", on_close)
        self.add_action(close)

        def on_about(action: Gio.Action, parameters: None) -> None:
            self._about_window.show()
        about = Gio.SimpleAction.new("about", None)
        about.connect("activate", on_about)
        self.add_action(about)

        def on_add_files(action: Gio.Action, parameters: None) -> None:
            self._file_chooser_dialog.show()
        add_files = Gio.SimpleAction.new("add-files", None)
        add_files.connect("activate", on_add_files)
        self.add_action(add_files)

        def on_add_folders(action: Gio.Action, parameters: None) -> None:
            self._folder_chooser_dialog.show()
        add_folders = Gio.SimpleAction.new("add-folders", None)
        add_folders.connect("activate", on_add_folders)
        self.add_action(add_folders)

        def on_remove_file(
                action: Gio.Action,
                parameters: GLib.Variant) -> None:
            self.file_store.remove_file_with_index(parameters.get_uint32())
        remove_file = Gio.SimpleAction.new(
            "remove-file",
            GLib.VariantType.new("u"))
        remove_file.connect("activate", on_remove_file)
        self.add_action(remove_file)

        def on_clear_files(action: Gio.Action, parameters: None) -> None:
            self.file_store.remove_files()
        clear_files = Gio.SimpleAction.new("clear-files", None)
        clear_files.connect("activate", on_clear_files)
        clear_files.set_enabled(False)
        self.add_action(clear_files)

        def on_view_details(
                action: Gio.Action,
                parameters: GLib.Variant) -> None:
            f = self.file_store.get_file_with_index(parameters.get_uint32())
            self._details_view.view_file(f)
            self.open_details_view()
        view_details = Gio.SimpleAction.new(
            "view-details",
            GLib.VariantType.new("u"))
        view_details.connect("activate", on_view_details)
        self.add_action(view_details)

        def on_close_details_view(
                action: Gio.Action,
                parameters: None) -> None:
            self.close_details_view()
        close_details_view = Gio.SimpleAction.new(
            "close-details-view",
            None)
        close_details_view.connect("activate", on_close_details_view)
        self.add_action(close_details_view)

        def on_clean_metadata(action: Gio.Action, parameters: None) -> None:
            self.close_details_view()
            if not self.get_application() \
                    .settings.get_boolean("cleaning-without-warning"):
                self._cleaning_warning_dialog.show()
                return
            self.file_store.clean_files()
        clean_metadata = Gio.SimpleAction.new("clean-metadata", None)
        clean_metadata.connect("activate", on_clean_metadata)
        clean_metadata.set_enabled(False)
        self.add_action(clean_metadata)

    # SIGNALS

    @Gtk.Template.Callback()
    def _on_mode_flap_revealed(
            self,
            flap: Adw.Flap,
            p_spec: GObject.ParamSpec) -> None:
        if not flap.get_reveal_flap():
            self.close_details_view()

    @Gtk.Template.Callback()
    def _on_file_chooser_dialog_response(
            self,
            dialog: FileChooserDialog,
            response: Gtk.ResponseType) -> None:
        dialog.hide()
        if response == Gtk.ResponseType.ACCEPT:
            self.file_store.add_gfiles(dialog.get_files())

    @Gtk.Template.Callback()
    def _on_folder_chooser_dialog_response(
            self,
            dialog: FolderChooserDialog,
            response: Gtk.ResponseType) -> None:
        dialog.hide()
        if response == Gtk.ResponseType.ACCEPT:
            self.file_store.add_gfiles(
                dialog.get_files(),
                dialog.get_choice("recursive") == "true")

    @Gtk.Template.Callback()
    def _on_cleaning_warning_dialog_response(
            self,
            dialog: CleaningWarningDialog,
            response: Gtk.ResponseType) -> None:
        dialog.hide()
        if response == Gtk.ResponseType.OK:
            self.file_store.clean_files()

    # VIEWS #

    def show_empty_view(self) -> None:
        """Show an empty view."""
        self._view_stack.set_visible_child_name("empty")
        self.lookup_action("clear-files").set_enabled(False)

    def show_files_view(self) -> None:
        """Show the files."""
        self._view_stack.set_visible_child_name("files")
        self.lookup_action("clear-files").set_enabled(True)

    def open_details_view(self) -> None:
        """Show the details view."""
        self._mode_flap.set_reveal_flap(True)

    def close_details_view(self) -> None:
        """Close the details view."""
        self._mode_flap.set_reveal_flap(False)
        self._view_stack.get_child_by_name("files").clear_selected_file()
