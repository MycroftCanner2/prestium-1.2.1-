# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Dialog warning the user of possible data loss on cleaning."""

from gi.repository import Gio, GObject, Gtk


@Gtk.Template(
    resource_path=(
        "/fr/romainvigier/MetadataCleaner/ui/CleaningWarningDialog.ui")
)
class CleaningWarningDialog(Gtk.MessageDialog):
    """Dialog warning the user of possible data loss on cleaning."""

    __gtype_name__ = "CleaningWarningDialog"

    settings = GObject.Property(type=Gio.Settings)

    _checkbutton: Gtk.CheckButton = Gtk.Template.Child()

    @Gtk.Template.Callback()
    def _on_settings_changed(self, dialog, p_spec: GObject.ParamSpec) -> None:
        if not self.settings:
            return
        self.settings.bind(
            "cleaning-without-warning",
            self._checkbutton,
            "active",
            Gio.SettingsBindFlags.DEFAULT)
