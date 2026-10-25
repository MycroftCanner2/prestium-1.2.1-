# SPDX-FileCopyrightText: Metadata Cleaner contributors
# SPDX-License-Identifier: GPL-3.0-or-later

"""Files Manager object and states."""

import libmat2
import mimetypes

from concurrent.futures import ThreadPoolExecutor, as_completed
from enum import IntEnum, auto
from gi.repository import Gio, GLib, GObject
from threading import Thread
from typing import Dict, Iterable, List, Optional

from metadatacleaner.modules.file import File, FileState
from metadatacleaner.modules.logger import Logger as logger


def _get_supported_formats() -> Dict:
    formats = {}
    for parser in libmat2.parser_factory._get_parsers():
        for mimetype in parser.mimetypes:
            extensions = set()
            for extension in mimetypes.guess_all_extensions(mimetype):
                if extension not in libmat2.UNSUPPORTED_EXTENSIONS:
                    extensions.add(extension)
            if not extensions:
                continue
            formats[mimetype] = extensions
    return formats


SUPPORTED_FORMATS = _get_supported_formats()


class FileStoreState(IntEnum):
    """States the Files Manager can have."""

    IDLE = auto()
    WORKING = auto()


class FileStoreAction(IntEnum):
    """Actions the Files manager can do."""

    ADDING = auto()
    CLEANING = auto()


class FileStore(Gio.ListStore):
    """File Store object."""

    __gtype_name__ = "FileStore"

    __gsignals__ = {
        "file-state-changed": (GObject.SIGNAL_RUN_LAST, None, (int,)),
        "state-changed": (GObject.SIGNAL_RUN_LAST, None, (int,)),
        "progress-changed": (GObject.SIGNAL_RUN_LAST, None, (int, int))
    }

    lightweight_mode: bool = GObject.Property(
        type=bool,
        nick="lightweight-mode",
        default=False)

    def __init__(self) -> None:
        """File Store initialization."""
        Gio.ListStore.__init__(self, item_type=File)
        self.state = FileStoreState.IDLE
        self.last_action: Optional[FileStoreAction] = None
        self.progress = (0, 0)
        self.add_files_executor = ThreadPoolExecutor()
        self.clean_files_executor = ThreadPoolExecutor()

    def _on_file_state_changed(self, f: File, new_state: FileState) -> None:
        def emit() -> bool:
            self.emit("file-state-changed", self.get_index_of_file(f))
            return GLib.SOURCE_REMOVE
        GLib.idle_add(emit)

    def _set_state(self, state: FileStoreState) -> None:
        if state == self.state:
            return
        self.state = state

        def emit() -> bool:
            self.emit("state-changed", state)
            return GLib.SOURCE_REMOVE
        GLib.idle_add(emit)

    def _set_progress(self, current: int, total: int) -> None:
        self.progress = (current, total)

        def emit() -> bool:
            self.emit("progress-changed", current, total)
            return GLib.SOURCE_REMOVE
        GLib.idle_add(emit)

    def get_files(self) -> List[File]:
        """Get all the files from the File Store.

        Returns:
            List[File]: List of files.
        """
        return self

    def get_file_with_index(self, index: int) -> File:
        """Get a file at a specified index.

        Args:
            index (int): The desired index.

        Returns:
            Optional[File]: The file if found, else None.
        """
        f = self.get_item(index)
        if not f:
            raise RuntimeError("No file in the file store for this index.")
        return f

    def get_index_of_file(self, f: File) -> int:
        """Get the index of a given file.

        Args:
            f (File): The file to get the index for.

        Returns:
            int: The file index.
        """
        found, position = self.find(f)
        if not found:
            raise RuntimeError("File not found in file store.")
        return position

    def add_gfiles(
            self, gfiles: List[Gio.File], recursive: bool = True) -> None:
        """Add Gio Files to the Files Manager.

        Args:
            gfiles (List[Gio.File]): List of Gio Files to add.
            recursive (bool, optional): If subdirectories should also be looked
            into. Defaults to True.
        """
        thread = Thread(
            target=self._add_gfiles_async,
            args=(gfiles, recursive),
            daemon=True)
        thread.start()

    def _add_gfiles_async(
            self, gfiles: List[Gio.File], recursive: bool = True) -> None:
        self._set_state(FileStoreState.WORKING)
        all_gfiles = self._gather_all_gfiles(gfiles, recursive)
        self._set_progress(
            self.progress[0], self.progress[1] + len(all_gfiles))
        self.last_action = FileStoreAction.ADDING
        futures = {
            self.add_files_executor.submit(self._add_gfile, gfile)
            for gfile in all_gfiles
        }
        for future in as_completed(futures):
            current = self.progress[0] + 1
            total = self.progress[1]
            self._set_progress(current, total)
            if current == total:
                self._stop_adding_gfiles()

    def _gather_all_gfiles(
            self,
            gfiles: List[Gio.File],
            recursive: bool = True) -> List[Gio.File]:
        all_gfiles: List[Gio.File] = []
        for gfile in gfiles:
            if not gfile:
                continue
            f_type = gfile.query_file_type(Gio.FileQueryInfoFlags.NONE, None)
            if f_type == Gio.FileType.DIRECTORY:
                all_gfiles.extend(self._get_gfiles_from_dir(gfile, recursive))
            elif f_type == Gio.FileType.REGULAR:
                all_gfiles.append(gfile)
            else:
                logger.warning(
                    f"File {gfile.get_path()} is neither a directory nor a "
                    "regular file, skipping.")
        return all_gfiles

    def _get_gfiles_from_dir(
            self, dir: Gio.File, recursive: bool) -> List[Gio.File]:
        gfiles: List[Gio.File] = []
        subdirs: List[Gio.File] = []
        children_enumerator = dir.enumerate_children(
            "",
            Gio.FileQueryInfoFlags.NONE,
            None)
        while True:
            info = children_enumerator.next_file(None)
            if info is None:
                break
            child = children_enumerator.get_child(info)
            if info.get_file_type() == Gio.FileType.DIRECTORY:
                if recursive:
                    subdirs.append(child)
            elif info.get_file_type() == Gio.FileType.REGULAR:
                gfiles.append(child)
        children_enumerator.close(None)
        with ThreadPoolExecutor() as executor:
            for subgfiles in executor.map(
                    self._get_gfiles_from_dir,
                    subdirs,
                    [recursive] * len(subdirs)):
                gfiles.extend(subgfiles)
        return gfiles

    def _add_gfile(self, gfile: Gio.File) -> None:
        if not gfile.query_exists(None):
            logger.warning(
                f"File {gfile.get_path()} does not exist, skipping.")
            return

        if bool(list(filter(lambda x: x.path == gfile.get_path(), self))):
            logger.warning(f"Skipping {gfile.get_path()}, already added.")
            return

        f = File(gfile)
        f.check_metadata()

        def finish() -> bool:
            self.append(f)
            f.connect("state-changed", self._on_file_state_changed)
            return GLib.SOURCE_REMOVE
        GLib.idle_add(finish)

    def _stop_adding_gfiles(self) -> None:
        self.add_files_executor.shutdown(wait=False, cancel_futures=True)
        self.add_files_executor = ThreadPoolExecutor()
        self._set_state(FileStoreState.IDLE)
        self._set_progress(0, 0)

    def cancel_addding_gfiles(self) -> None:
        """Cancel adding GFiles."""
        self._stop_adding_gfiles()

    def remove_file(self, f: File) -> None:
        """Remove a file from the File Store.

        Args:
            f (File): The file to remove.
        """
        self.remove_file_with_index(self.get_index_of_file(f))

    def remove_file_with_index(self, index: int) -> None:
        """Remove the file with the given index from the File Store.

        Args:
            index (int): The index of the file to remove.
        """
        self.remove(index)

    def remove_files(self) -> None:
        """Remove all the files from the File Store."""
        self.remove_all()

    def clean_files(self) -> None:
        """Remove metadata from all the cleanable files."""
        thread = Thread(target=self._clean_files_async, daemon=True)
        thread.start()

    def _clean_files_async(self) -> None:
        cleanable_files = self.get_cleanable_files()
        self._set_progress(
            self.progress[0], self.progress[1] + len(cleanable_files))
        self._set_state(FileStoreState.WORKING)
        self.last_action = FileStoreAction.CLEANING
        futures = {
            self.clean_files_executor.submit(f.clean, self.lightweight_mode)
            for f in cleanable_files
        }
        for future in as_completed(futures):
            current = self.progress[0] + 1
            total = self.progress[1]
            self._set_progress(current, total)
        self._stop_cleaning_files()

    def _stop_cleaning_files(self) -> None:
        self.clean_files_executor.shutdown(wait=False, cancel_futures=True)
        self.clean_files_executor = ThreadPoolExecutor()
        self._set_state(FileStoreState.IDLE)
        self._set_progress(0, 0)

    def cancel_cleaning_files(self) -> None:
        """Cancel the cleaning process."""
        self._stop_cleaning_files()

    def get_cleanable_files(self) -> List[File]:
        """Get all the cleanable files.

        Returns:
            List[File]: List of cleanable files.
        """
        return self._get_files_with_states((
            FileState.HAS_METADATA,
            FileState.HAS_NO_METADATA))

    def get_cleaned_files(self) -> List[File]:
        """Get all the cleaned files.

        Returns:
            List[File]: List of cleaned files.
        """
        return self._get_files_with_states((FileState.CLEANED,))

    def get_errored_files(self) -> List[File]:
        """Get all the files with errors.

        Returns:
            List[File]: List of files with errors.
        """
        return self._get_files_with_states((
            FileState.ERROR_WHILE_INITIALIZING,
            FileState.ERROR_WHILE_CHECKING_METADATA,
            FileState.ERROR_WHILE_REMOVING_METADATA))

    def _get_files_with_states(
            self,
            states: Iterable[FileState]) -> List[File]:
        return list(filter(lambda f: f.state in states, self))
