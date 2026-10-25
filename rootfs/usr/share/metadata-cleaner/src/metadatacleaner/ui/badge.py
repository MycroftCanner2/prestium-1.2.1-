# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Badge to display information."""

from gi.repository import Adw, Gtk


@Gtk.Template(resource_path="/fr/romainvigier/MetadataCleaner/ui/Badge.ui")
class Badge(Adw.Bin):
    """Badge to display information."""

    __gtype_name__ = "Badge"
