
import ctypes
import enum
import logging
import os
import platform
import time

from pathlib import Path


# -- Constants -- #
APP_BASE = Path(__file__).resolve(strict=True).parent.parent.parent


# datefmt = '%Y%m%d %I:%M:%S%p'
# formatter = '%(asctime)s %(levelname)s %(funcName)s: %(message)s'
# logging.basicConfig(
#     format=formatter,
#     datefmt=datefmt,
#     level=logging.DEBUG,
# )
# log = logging.getLogger('orion.framework.helpers.utils_filesystem')
log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)


# ---------------------------------------------------------- #

# --
# File and Dir Searching or File List Builders
# --

def get_finished_dirlist(input_dir):
    """ Testing new method to get list of all dirs that are considered complete.

        TODO: I'll benchmark this method against my original method below to see which is most efficient.

    """
    log.info("Scanning provided dir for ones that are marked as complete. Please wait...")
    dirlist = os.listdir(input_dir)
    if not dirlist: return

    completed_dirs = []
    start_time = time.perf_counter()
    for dir in dirlist:
        # Search for our directory tag that indicates a dir is done with scan processing
        if dir.endswith("_done"):
            # We have a completed directory
            #log.debug(f"Found completed dir: {dir}")
            completed_dirs.append(Path.joinpath(input_dir, dir))
    end_time = time.perf_counter() - start_time
    log.info(f"Dir scan finished in {end_time:0.2f} seconds")
    return completed_dirs


def move_completed_dir(input_dir):
    """ Rename a completed directory as part of processing. """
    log.debug(f"Checking input_dir before rename: {input_dir}")

    if not os.path.isdir(input_dir):
        log.critical(f"Provided path for renaming is not a directory: {input_dir}")
        return

    # TODO: Change this function to place the done directory into an "imported" sub-directory
    input_dir = Path(input_dir)

    dir_parent = input_dir.parent
    new_dir = dir_parent / f"{input_dir.stem}_imported"

    os.rename(input_dir, new_dir)
    log.debug(f"Move: {input_dir} has been renamed to {new_dir}")
    return


def get_dir_list_for_search(input_dir):
    """

    """
    start_time = time.perf_counter()
    log.info("Scanning provided dir for specific file recursively. Please wait...")
    dirs_list = []
    for root, dirs, filenames in os.walk(input_dir):
        # TODO: Search for dirs containing a pattern, like .endswith("_imported")
            dirs_list.append(root)

    log.info(f"Found {len(dirs_list):,d} matching directory paths")
    end_time = time.perf_counter() - start_time
    log.info(f"Dir Scan took {end_time:0.2f} seconds")
    return dirs_list


def get_file_list_for_search(input_dir, search_filename):
    """
    Return a list of full file paths for all recursively found files in provided input_dir.

    get_file_list_for_search(input_dir, "file.csv")
    """
    start_time = time.perf_counter()
    log.info("Scanning provided dir for specific file recursively. Please wait...")
    files_list = []
    for root, dirs, filenames in os.walk(input_dir):
        if not filenames: continue
        if root.endswith("_imported"): continue
        if not root.endswith("_done"): continue
        if os.path.exists(os.path.join(root, search_filename)):
            files_list.append(os.path.join(root, search_filename))

    log.info(f"Found {len(files_list):,d} matching file paths")
    end_time = time.perf_counter() - start_time
    log.info(f"File search took {end_time:0.2f} seconds")
    return files_list




def clean_merged_dir(target_dir):
    """ Do a quick clean of the specified dir before starting any new merge operations.
    """
    if not os.path.isdir(target_dir):
        log.debug("merged_dir doesn't exist yet, must be a new group")
        return

    log.info("Cleaning up the merged directory")
    for merged_file in os.listdir(target_dir):
        if merged_file.endswith(".csv"):
            log.debug(f"Deleting {merged_file}")
            os.unlink(Path.joinpath(target_dir, merged_file))
        else:
            log.warning(f"Skipping deletion because current file is not a CSV: {Path.joinpath(target_dir, merged_file)}")

    log.debug(f"Finished cleaning up directory: {target_dir}")
    return






# --
# File Sizes Handling
# --


class SIZE_UNIT(enum.Enum):
    """ Enum class obj used for the convert_size_unit helper function below. """
    BYTES = 1
    KB = 2
    MB = 3
    GB = 4

def convert_size_unit(size_in_bytes, unit=None):
    """ Helper Function - This is my own version I created
        Input a bytes size and return its human-readable size in the desired unit (kb, mb, gb)

        return 2-tuple (size:int, unit:str)

        Example:
            file_size_readable, size_unit = convert_size_unit(self.file_size)
			log.info(f"File size: {file_size_readable} {size_unit}")
    """
    # if not isinstance(size_in_bytes, int):
    #     log.error(f"Provided file size is not an integer, fix and try again. size var: {size_in_bytes}")
    #     return (0, '')

    size_in_bytes = int(size_in_bytes)

    # If we pass a specified UNIT label, use it and convert to that tens
    if unit == SIZE_UNIT.KB:
        return (size_in_bytes / 1024, "KB")
    elif unit == SIZE_UNIT.MB:
        return (size_in_bytes/(1024 * 1024), "MB")
    elif unit == SIZE_UNIT.GB:
        return (size_in_bytes/(1024 * 1024 * 1024), "GB")
    else:
        # If a unit was NOT provided, calculate the largest possible tens and use that
        if size_in_bytes > 1099511627776:
            return (f"{size_in_bytes / (1024 * 1024 * 1024 * 1024):,.1f}", "TB")
        if size_in_bytes > 1073741824:
            return (f"{size_in_bytes / (1024 * 1024 * 1024):,.1f}", "GB")
        elif size_in_bytes > 1048576:
            return (f"{size_in_bytes / (1024 * 1024):,.1f}", "MB")
        elif size_in_bytes > 1024:
            return (f"{size_in_bytes / 1024:,.1f}", "KB")
        else:
            return (size_in_bytes, "B")




def pretty_file_size(size, use_decimal=False, **kwargs):
    """
    Return a human-readable representation of the provided ``size``.

    :param size: The size to convert
    :param use_decimal: use decimal instead of binary prefixes (e.g. kilo = 1000 instead of 1024)

    :keyword units: A list of unit names in ascending order.
        Default units: ['B', 'KB', 'MB', 'GB', 'TB', 'PB']

    :return: The converted size
    """
    try:
        size = max(float(size), 0.0)
    except (ValueError, TypeError):
        size = 0.0

    remaining_size = size
    units = kwargs.pop("units", ["B", "KB", "MB", "GB", "TB", "PB"])
    block = 1024.0 if not use_decimal else 1000.0
    for unit in units:
        if remaining_size < block:
            return "{0:3.2f} {1}".format(remaining_size, unit)
        remaining_size /= block
    return size



def humanize_bytes(byte_count, precision=1):
    """Return a humanized string representation of a number of bytes.
        >>> humanize_bytes(1)
        '1 byte'
        >>> humanize_bytes(1024)
        '1.0 kB'
        >>> humanize_bytes(1024*123)
        '123.0 kB'
        >>> humanize_bytes(1024*12342)
        '12.1 MB'
        >>> humanize_bytes(1024*12342,2)
        '12.05 MB'
        >>> humanize_bytes(1024*1234,2)
        '1.21 MB'
        >>> humanize_bytes(1024*1234*1111,2)
        '1.31 GB'
        >>> humanize_bytes(1024*1234*1111,1)
        '1.3 GB'
    """
    if byte_count == 1:
        return '1 byte'
    if byte_count < 1024:
        '{0:0.{1}f} {2}'.format(byte_count, 0, 'bytes')

    suffixes = ['KB', 'MB', 'GB', 'TB', 'PB']
    multiple = 1024.0  # .0 to force float on python 2
    for suffix in suffixes:
        byte_count /= multiple
        if byte_count < multiple:
            return '{0:0.{1}f} {2}'.format(byte_count, precision, suffix)
    return '{0:0.{1}f} {2}'.format(byte_count, precision, suffix)



def get_disk_usage(input_path):
    """ Get disk usage and return back ...

    """
    if platform.system() == "Windows":
        free = ctypes.c_ulonglong(0)
        if ctypes.windll.kernel32.GetDiskFreeSpaceExW(ctypes.c_wchar_p(str(input_path)), None, None, ctypes.pointer(free)) == 0:
            raise ctypes.WinError()
        return free.value

    elif hasattr(os, "statvfs"):  # POSIX
        if platform.system() == "Darwin":
            try:
                import subprocess

                call = subprocess.Popen(["df", "-k", input_path], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                output = call.communicate()[0]
                return int(output.split("\n")[1].split()[3]) * 1024
            except Exception:
                pass

        st = os.statvfs(input_path)
        return st.f_bavail * st.f_frsize

    else:
        raise Exception("Unable to determine free space on your OS")


def check_freespace_low(input_path, min_threshold=None):
    """ Verify the current free space amount and if it is below the desired minimum threshold (True) or not (False). """

    if not min_threshold:
        min_threshold = 5000000     # roughly 5 GB of size
    log.debug(f"Checking free space on input path {input_path}")

    disk_free = get_disk_usage(input_path)
    disk_free_readable = pretty_file_size(disk_free)

    if disk_free < min_threshold:
        log.warning(f"Disk space is getting critically low and is below your minimum threshold. Current free space available: {disk_free_readable}")
        return True

    #print(f"Disk Free: {disk_free}")
    #print(f"Disk Free (Readable): {disk_free_readable}")

    return False



if __name__ == '__main__':
    check_freespace_low('/data')