# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Indicator showing the status of the files manager."""

from gettext import gettext as _
from gettext import ngettext as __
from gi.repository import Gio, GLib, GObject, Gtk

from metadatacleaner.modules.filestore \
    import FileStore, FileStoreAction, FileStoreState


@Gtk.Template(
    resource_path="/fr/romainvigier/MetadataCleaner/ui/StatusIndicator.ui"
)
class StatusIndicator(Gtk.Stack):
    """Indicator showing the status of the files manager."""

    __gtype_name__ = "StatusIndicator"

    file_store: FileStore = GObject.Property(type=FileStore, nick="file-store")

    _progressbar: Gtk.ProgressBar = Gtk.Template.Child()
    _done_label: Gtk.Label = Gtk.Template.Child()

    def __init__(self, *args, **kwargs) -> None:
        """Status indicator initialization."""
        super().__init__(*args, **kwargs)
        self.show_idle()

    def _sync_progressbar(self, current, total) -> None:
        if not self.file_store or not self.file_store.last_action:
            return
        text = {
            FileStoreAction.ADDING:
                _("Processing file {}/{}").format(current, total),
            FileStoreAction.CLEANING:
                _("Cleaning file {}/{}").format(current, total),
        }
        self._progressbar.set_text(text[self.file_store.last_action])
        self._progressbar.set_fraction(current / total if total > 0 else 0)

    @Gtk.Template.Callback()
    def _on_file_store_changed(
            self,
            widget: Gtk.Widget,
            pspec: GObject.ParamSpec) -> None:
        self.file_store.connect(
            "state-changed",
            self._on_file_store_state_changed)
        self.file_store.connect(
            "progress-changed",
            self._on_file_store_progress_changed)

    @Gtk.Template.Callback()
    def _on_cancel_button_clicked(self, button: Gtk.Button) -> None:
        if self.file_store.last_action == FileStoreAction.ADDING:
            self.file_store.cancel_addding_gfiles()
        elif self.file_store.last_action == FileStoreAction.CLEANING:
            self.file_store.cancel_cleaning_files()

    def _on_file_store_state_changed(
            self,
            file_store: FileStore,
            new_state: FileStoreState) -> None:
        if new_state == FileStoreState.WORKING:
            self.show_progressbar()

    def _on_file_store_progress_changed(
            self,
            file_store: FileStore,
            current: int,
            total: int) -> None:
        self._sync_progressbar(current, total)
        if current == total:
            if file_store.last_action == FileStoreAction.CLEANING:
                clean_message = __(
                    "%i file cleaned.",
                    "%i files cleaned.",
                    len(file_store.get_cleaned_files())
                ) % len(file_store.get_cleaned_files())
                error_message = (__(
                    "%i error occured.",
                    "%i errors occured.",
                    len(file_store.get_errored_files())
                ) % len(file_store.get_errored_files())
                    if len(file_store.get_errored_files()) > 0
                    else "")
                self._done_label.set_label(
                    " ".join([clean_message, error_message]))
                if not self.get_root().is_active():
                    self.send_done_notification()
            else:
                self._done_label.set_label("")
            self.show_done()

    def show_idle(self) -> None:
        """Show the idle state."""
        self.set_visible_child_name("idle")

    def show_progressbar(self) -> None:
        """Show a progress bar."""
        self.set_visible_child_name("working")

    def show_done(self) -> None:
        """Show a "Done" message."""
        self.set_visible_child_name("done")

    def send_done_notification(self) -> None:
        """Send a notification about the finished cleaning process."""
        window = self.get_root()
        app = window.get_application()
        notification = Gio.Notification.new(app.name)
        notification.set_body(self._done_label.get_label())
        notification.set_default_action_and_target(
            "app.show-window",
            GLib.Variant.new_uint32(window.get_id()))
        app.send_notification(f"done{window.get_id()}", notification)
