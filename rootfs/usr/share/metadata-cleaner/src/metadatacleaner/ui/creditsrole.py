# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Widget crediting persons for a role."""

import re

from gi.repository import GObject, Gtk


@Gtk.Template(
    resource_path="/fr/romainvigier/MetadataCleaner/ui/CreditsRole.ui"
)
class CreditsRole(Gtk.Box):
    """Widget crediting persons for a role."""

    __gtype_name__ = "CreditsRole"

    role = GObject.Property(type=str)

    _persons_label: Gtk.Label = Gtk.Template.Child()

    _persons = ""

    @GObject.Property(type=str)
    def persons(self) -> str:
        """Get the persons string.

        Returns:
            str: The persons string.
        """
        return self._persons

    @persons.setter  # type: ignore
    def persons(self, value: str) -> None:
        self._persons = value
        if value:
            self._persons_label.set_label(_parse_links(value))


def _parse_links(string: str) -> str:
    lines = string.splitlines()
    parsed_lines = []
    regex_email = re.compile("<(.+)>")
    regex_url = re.compile("https?://\\S+")
    for line in lines:
        match_email = regex_email.search(line)
        match_url = regex_url.search(line)
        if match_email:
            name = line[:match_email.start()].strip()
            url = f"mailto:{match_email.group()[1:-1]}"
            parsed_lines.append(f"<a href='{url}'>{name}</a>")
        elif match_url:
            name = line[:match_url.start()].strip()
            url = match_url.group()
            parsed_lines.append(f"<a href='{url}'>{name}</a>")
        else:
            parsed_lines.append(line)
    return "\n".join(parsed_lines)
