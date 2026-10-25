# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""List of a file's metadata."""

from gi.repository import GObject, Gtk

from metadatacleaner.modules.metadata import MetadataList

from metadatacleaner.ui.metadatadetailsrow import MetadataDetailsRow


@Gtk.Template(
    resource_path="/fr/romainvigier/MetadataCleaner/ui/MetadataDetails.ui"
)
class MetadataDetails(Gtk.Box):
    """List of a file's metadata."""

    __gtype_name__ = "MetadataDetails"

    filename = GObject.Property(type=str)

    _metadata_list = MetadataList()

    _list: Gtk.ListBox = Gtk.Template.Child()

    @GObject.Property(type=MetadataList)
    def metadata_list(self) -> MetadataList:
        """Metadata List.

        Returns:
            MetadataList: A list of Metadata.
        """
        return self._metadata_list

    @metadata_list.setter  # type: ignore
    def metadata_list(self, metadata_list):
        self._metadata_list = metadata_list
        self._list.bind_model(metadata_list, _create_row)


def _create_row(metadata):
    return MetadataDetailsRow(key=metadata.key, value=metadata.value)
