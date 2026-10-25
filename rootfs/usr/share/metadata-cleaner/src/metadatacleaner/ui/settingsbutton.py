# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Settings button."""

from gi.repository import Gtk


@Gtk.Template(
    resource_path="/fr/romainvigier/MetadataCleaner/ui/SettingsButton.ui"
)
class SettingsButton(Gtk.MenuButton):
    """Settings button."""

    __gtype_name__ = "SettingsButton"
