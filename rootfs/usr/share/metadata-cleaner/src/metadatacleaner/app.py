# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Application for Metadata Cleaner."""

from gettext import gettext as _
from gi.repository import Adw, Gdk, Gio, GLib, GObject, Gtk
from typing import List, Optional

from metadatacleaner.ui.window import Window


class MetadataCleaner(Adw.Application):
    """Application for Metadata Cleaner."""

    __gtype_name__ = "MetadataCleaner"

    devel = GObject.Property(type=bool, default=False)
    settings = GObject.Property(type=Gio.Settings)
    version = GObject.Property(type=str)

    def __init__(
            self,
            devel: bool,
            version: str,
            *args,
            **kwargs) -> None:
        """Application initialization.

        Args:
            app_id (str): Application ID
            version (str): Version string
        """
        super().__init__(
            flags=Gio.ApplicationFlags.HANDLES_OPEN,
            *args,
            **kwargs)
        self.name = _("Metadata Cleaner")
        self.devel = devel
        self.version = version
        self.settings = Gio.Settings.new(self.get_application_id())

    # APPLICATION METHODS #

    def do_activate(self) -> None:
        """Run on application activation."""
        self.new_window()

    def do_startup(self) -> None:
        """Run on application startup."""
        Adw.Application.do_startup(self)
        self._setup_actions()
        self._setup_accels()

    def do_open(self, gfiles: List[Gio.File], n_files: int, hint: str) -> None:
        """Run when files are passed to the command line."""
        self.new_window(gfiles=gfiles)

    # SETUP #

    def _setup_actions(self) -> None:

        def on_show_help(action: Gio.Action, parameters: GLib.Variant) -> None:
            Gtk.show_uri(
                self.get_active_window(),
                f"help:{self.get_application_id()}{parameters.get_string()}",
                Gdk.CURRENT_TIME)
        show_help = Gio.SimpleAction.new("help", GLib.VariantType.new("s"))
        show_help.connect("activate", on_show_help)
        self.add_action(show_help)

        def on_show_window(
                action: Gio.Action,
                parameters: GLib.Variant) -> None:
            window_id = parameters.get_uint32()
            window = self.get_window_by_id(window_id)
            window.present_with_time(Gdk.CURRENT_TIME)
            self.withdraw_notification(f"done{window_id}")
        show_window = Gio.SimpleAction.new(
            "show-window",
            GLib.VariantType.new("u"))
        show_window.connect("activate", on_show_window)
        self.add_action(show_window)

        def on_new_window(action: Gio.Action, parameters: None) -> None:
            self.new_window()
        new_window = Gio.SimpleAction.new("new-window", None)
        new_window.connect("activate", on_new_window)
        self.add_action(new_window)

        def on_quit_app(action: Gio.Action, parameters: None) -> None:
            for window in self.get_windows():
                self.withdraw_notification(f"done{window.get_id()}")
            self.quit()
        quit_app = Gio.SimpleAction.new("quit", None)
        quit_app.connect("activate", on_quit_app)
        self.add_action(quit_app)

        self.add_action(self.settings.create_action("lightweight-cleaning"))

    def _setup_accels(self) -> None:
        self.set_accels_for_action("app.help::/index", ["F1"])
        self.set_accels_for_action("app.new-window", ["<Control>n"])
        self.set_accels_for_action("app.quit", ["<Control>q"])
        self.set_accels_for_action("win.add-files", ["<Control>o"])
        self.set_accels_for_action("win.add-folders", ["<Control><Shift>o"])
        self.set_accels_for_action("win.clear-files", ["<Control>r"])
        self.set_accels_for_action("win.clean-metadata", ["<Control>m"])
        self.set_accels_for_action("win.close", ["<Control>w"])

    # PUBLIC #

    def new_window(self, gfiles: Optional[List[Gio.File]] = None) -> None:
        """Create a new window.

        Args:
            gfiles (List[Gio.File], optional): List of files to be added to the
                new window. Defaults to None.
        """
        def on_window_destroyed(window) -> None:
            self.withdraw_notification(f"done{window.get_id()}")
        window = Window(application=self)
        window.connect("destroy", on_window_destroyed)
        window.present()
        if gfiles:
            window.file_store.add_gfiles(gfiles)
