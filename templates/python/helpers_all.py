import asyncio          # NOTE: asyncio requires python 3.7+
import csv
import datetime
import functools
import glob
import json
import logging
import os
import re
import sys
import zipfile
from io import BytesIO
from pathlib import Path
from zipfile import ZipFile

import urllib.error
import urllib.parse
from urllib.parse import urlparse, unquote
from urllib.request import urlopen

import pandas as pd
import requests
from tqdm import tqdm

log = logging.getLogger(__name__)




# --
# Dirty Data Cleaning
# ----------------------------

def coalesce(*values):
    """ Return the first non-None value or None if all values are None. """
    return next((v for v in values if v is not None), None)



def safe_get(collection, key, default=None):
    """ Get values from a collection without raising errors.

    Extract data from dict or list universally, pass key for dict
    or index number for list.
    """
    try:
        return collection.get(key, default)
    except TypeError:
        pass
    try:
        return collection[key]
    except (IndexError, TypeError):
        pass
    return default


def nested_dig(collection, *keys, default=None):
    """ Get values from a nested collection without raising errors.

    Ex: medium_story.views_30days = nested_dig(story, "stats", "views_30days")

    """
    from functools import reduce
    return reduce(lambda x, y: safe_get(x, y, default), keys, collection)



def safe_cast(value, astype, default=None):
    """
    Return a converted value type or the default (None) if it
    raises an error that we pass over.

    Ex: convert string to int, handling if input is empty
            safe_cast(employee_data["age"], int)
    """
    try:
        return astype(value)
    except (TypeError, ValueError):
        pass
    return default





# ----------------------
#   URL Helpers
# ----------------------

def filename_from_url(url: str) -> str:
    """ Get accurate filename from a provided URL. """
    # from urllib.parse import urlparse
    url_parsed = urlparse(url)
    # unquote helps ensure encoding is undone, like %20 back to a space
    filename = unquote(Path(url_parsed.path).name)
    log.debug(f"URL: {url} - Extracted Filename: {filename}")
    #return url.split("/")[-1].split('?')[0]
    return filename


def is_local_path(input_path):
    """ Determine if provide input path is remote URL or local filepath. """
    url_parsed = urlparse(input_path)
    if url_parsed.scheme in ('file', ''): # Possibly a local file
        return os.path.exists(url_parsed.path)
    return False


def urlify_replace_spaces(url):
    """ Input a URL and return back that URL that is URL encoded for safe HTTP transmission. """
    return urllib.urlencode(url)
    #return url.strip().replace(" ", '%20')


def get_file_linecount(input_file):
    """ Most resource efficient way of getting line count of a file. """
    if not os.path.exists(input_file):
        return
    return sum(1 for _ in open(input_file))




def dicthasher(data: dict, n_bytes = 8) -> int:
    import hashlib
    if not data:
        raise Exception("Hashed dictionary can't be empty")

    data = json.dumps(data, sort_keys=True).encode('utf-8')
    hash_s = hashlib.sha256(data).digest()[:n_bytes]
    hash_i = int.from_bytes(hash_s, 'little')

    return hash_i


def filename_hasher(filename: str) -> int:

    # retrieve/only/this_part_of_the_file.json(.gz)
    filename = Path(filename).stem.split('.')[0]
    file_row = {'filename': filename}
    filename_hash = dicthasher(file_row)

    return filename_hash



# Build Exclusions List
def build_exclusions_list(exclusions_file):
    exclusions_list = set()
    if os.path.exists(exclusions_file):
        with open(exclusions_file, 'r') as f:
            for line in f:
                if line.strip().startswith("http"):
                    exclusions_list.add(line.strip())
        log.info(f"Exclusions loaded: {len(exclusions_list):,d} entries")
    else:
        log.error(f"Provided exclusions file is invalid! Skipping exclusions filtering.")
    return exclusions_list




def build_targets_queue(self):
    """ From a wide array of input methods, built a singular target list. """
    targets = []
    #log.debug(f"Excluded_urls in build_targets: {self.excluded_urls}")

    if not self.input_file:
        log.error("You must provide an input file or target when instantiating this class")
        sys.exit(1)

    # 1. A URL (non-file) was provided
    if isinstance(self.input_file, (list, set)):
        # Input is a list of URLs, common if we are doing TOC processing for network links
        for item in self.input_file:
            targets.append(item.strip())

    elif not os.path.isfile(self.input_file):
        targets.append(self.input_file)

    else:
        # 2. Input is a file
        ext = get_file_suffix(self.input_file)
        log.debug(f"Provided input is a file with extension: {ext}")

        # 2.1 Input is a txt file with a list of URLs
        if ext == '.txt':
            log.debug("Loading targets from [txt] file input")
            with open(self.input_file, 'r') as f:
                #targets = [line.strip() for line in f if line not in self.excluded_urls]
                for line in f:
                    line = line.strip()
                    targets.append(line)

        # 2.2. Input is a .csv file - TODO
        elif ext == '.csv':
            log.debug("Loading targets from [csv] file input")
            #for url in tqdm(self.load_links_csv(self.input_file)):
            #self.parse_index_file_links_new(targets_list, self.output_dir)
            pass

        # 2.3. Input is a .db file so we'll load it up
        elif ext == '.db':
            log.debug("Loading targets from [db] file input")
            d = MRFDB(self.input_file)
            # TODO: Make sure all future TOC scripts put urls into the 'urls' table
            for url in d.yield_all_urls(table='urls', column='url'):
            #for url in d.yield_all_urls_sorted(table='in_network_files', column='url'):
                log.debug(f"Add to targets list: {url}")
                targets.append(url)
                #log.debug(f"URL is new, adding to targets: {url}")

    log.debug(f"Targets Loaded: {len(targets):,d}")
    return targets






# --
# Merge Plaintext (.txt) files Together
# --


def merge_list_files(existing_file, newdata_file, output_filename=None):
    """ Take an existing file of data, a list/set of new data, and combine the two
        together into one returned set of both, de-duped, and saving list to file.

        NOTE: This original function was in artemis - process-amass-files.py
        Slight change in that this accepts both files rather than a data list.

        output_filename     If not specified, merged list will overwrite "existing_file" file
    """
    existing = set()
    newset = set()

    with open(existing_file, 'r') as rf:
        for line in rf:
            line = line.strip()
            if line.startswith("http"):
                existing.add(line)

    with open(newdata_file, 'r') as rf:
        for line in rf:
            line = line.strip()
            if line.startswith("http"):
                newset.add(line)

    # TODO: These printed values are off, but the resulting data written
    # to file is, in fact, unique entries and for some reason is a larger
    # number than what is printed on this last print() for unique results

    count_common_to_both = existing.intersection(newset)    # count of dupes
    count_diff = newset.difference(existing)                # new unique results
    print("[*] Existing data count: {}".format(len(list(existing))))
    print("[*] New data count: {}".format(len(list(newset))))
    print("[*] New common to both: {}".format(len(count_common_to_both)))
    print("[*] New unique results: {}".format(len(count_diff)))
    existing |= newset
    # return the new complete set of unique (de-duped) data

    # Save the unified data to either original or new file
    if output_filename:
        # TODO: may need a dir check here, but skipping for now
        save_all_targets_to_journal(output_filename, existing)
        log.info(f"Unified, deduped completed targets written and saved to: {output_filename}")
    else:
        save_all_targets_to_journal(existing_file, existing)
        log.info(f"Unified, deduped completed targets written and saved to: {existing_file}")
    return




def merge_all_list_files(input_files: list, output_filename):
    """ Combine many list files of the same type of data
        together into one returned set of both, de-duped, and saving list to file.

        output_filename     a full path to a new filename in which to save the final data
    """
    # Sanity checks
    if isinstance(input_files, str):
        if "," in input_files:
            input_files = input_files.split(",")

    unified_data = set()
    file_count = len(input_files)

    for input_file in input_files:
        counter = 0
        unique_count = 0
        line_count = 0
        try:
            with open(input_file, 'r') as rf:
                #line_count = sum(1 for row in rf.readlines())
                counter += 1
                for line in rf:
                    line_count += 1
                    line = line.strip()
                    #log.debug(f"Line: {line}")
                    if line.startswith("http"):
                        unified_data.add(line)
                        unique_count += 1
            log.info(f"Processed file ({counter}/{file_count}): {input_file}")
            log.info(f"\tOriginal lines: {line_count:,d}")
            log.info(f"\tUnique/Valid lines: {unique_count:,d}")
        except Exception as e:
            log.error(f"Error processing list file: {e}")
            log.debug(f"Errored filename: {input_file}")
            continue

    # Save the unified data to new file

    if not os.path.isdir(Path(output_filename).parent):
        os.makedirs(Path(output_filename).parent)

    if os.path.exists(output_filename):
        log.warning("Output file already exists, sure you want to overwrite it?")
        pass

    save_all_targets_to_journal(output_filename, unified_data)
    log.info(f"Unified, deduped completed targets written and saved to: {output_filename}")
    log.info(f"Final unique line count: {len(unified_data):,d}")

    return




# ----------------------
#   Download Helpers
# ----------------------


def download_from_googledrive(url, destination):
    """ Download a file from a Google Drive shareable URL.

        Usage: download_from_googledrive(url, '/media/public/temp/saved_file.csv')

        Help: https://stackoverflow.com/questions/38511444/python-download-files-from-google-drive-using-url
    """
    test_url = 'https://drive.google.com/uc?export=download&id=1I4zUrop3xGbXSutl_6-4Q72gFfJHRXeH'
    id = test_url.split('&id=')[1]

    session = requests.Session()
    response = session.get(url, params={'id': id}, stream=True)
    # token = get_confirm_token(response)
    token = None
    for key, value in response.cookies.items():
        if key.startswith('download_warning'):
            token = value
    if not token:
        log.error(f"Failed to extract token for downloading Google Drive resource")
        # TODO: Raise an error so caller can handle and skip parsing
        return False
    params = {'id': id, 'confirm': token}
    response = session.get(url, params=params, stream=True)
    #save_response_content(response, destination)
    CHUNK_SIZE = 32768
    with open(destination, "wb") as f:
        for chunk in response.iter_content(CHUNK_SIZE):
            if chunk:   # Filter out keep-alive new chunks
                f.write(chunk)
    return True



def download_file(url, destination):
        """ Download a file of any size.
        """
        USERAGENT='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36'
        headers = {'user-agent': USERAGENT}
        APP_BASE = Path(__file__).resolve(strict=True).parent.parent.parent

        if destination:
            local_filename = Path(destination)
        else:
            local_filename = filename_from_url(url)
            local_filename = APP_BASE / 'temp_downloads' / local_filename

        # local_filename = self.temp_download_dir / local_filename

        with requests.get(url, headers=headers, stream=True) as r:
            r.raise_for_status()
            with open(local_filename, 'wb') as f:
                for chunk in r.iter_content(chunk_size=8192):
                    f.write(chunk)
        return local_filename



# ----------------------
#   CSV Helpers
# ----------------------


def import_csv_to_set(filename: str):
    """Imports data as tuples from a given file."""

    items = set()
    with open(filename, 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            row = [col.strip() for col in row]
            if len(row) > 1:
                items.add(tuple(row))
            else:
                items.add(row.pop())
        return items




def dedupe_csv_polars(input_csv):

    import polars as pl

    file_path = Path(input_csv).resolve(strict=True).parent
    file_name_stem = Path(input_csv).stem
    new_name = file_path / f"{file_name_stem}_deduped.csv"


    df = pl.scan_csv(input_csv, infer_schema_length=0)
    df = df.unique()
    # df = df.collect()
    df.write_csv(new_name)
    return



def dedupe_csv_pandas(input_csv):
    """ Dedupe a single CSV file. """
    #import pandas as pd

    file_path = Path(input_csv).resolve(strict=True).parent
    file_name_stem = Path(input_csv).stem
    new_name = file_path / f"{file_name_stem}_deduped.csv"

    df = pd.read_csv(input_csv)
    df = df.drop_duplicates()

    df.to_csv(new_name, index=False)
    return new_name



def dedupe_many_csvs_pandas(input_path):
    #import pandas as pd
    from glob import glob

    csvs = glob(f"{input_path}/*.csv")

    for csv in csvs:
        df = pd.read_csv(csv, infer_schema_length=0)
        df = df.drop_duplicates()
        df.write_csv(csv)

    return



# --
# Merge Many CSV Files to One
# --
def merge_processed_csv_file(self, dirs_list, csv_filename):
    """ Merge hundreds of the same file type into a single, consolidate file of all the data.

        csv_filename            must be something like "file.csv", not a full path
    """


    # Put the new merged output file in our defined merged dir and ensure it exists
    new_filename = self.merged_dir / csv_filename

    if not os.path.isdir(self.merged_dir):
        os.makedirs(self.merged_dir)

    # For each, read in file, and write it to the new consolidated CSV file
    do_once = True

    for single_dir in tqdm(dirs_list):
        single_csv = os.path.join(single_dir, csv_filename)
        if not os.path.exists(single_csv):
            log.debug("Skipping a file that doesn't exist")
            continue
        log.debug(f"Reading file: {single_csv}")

        # Determine appropriate header/fieldnames & write them to our new file
        # Only do this once per entire file iteration.
        if do_once:
            with open(single_csv, 'r') as f:
                fieldnames = f.readline()
                fieldnames = fieldnames.split(",")
                fieldnames = [x.strip() for x in fieldnames]

            # This means if there's an existing file in the merged dir, it'll be blown away and start fresh
            with open(new_filename, 'w') as f_once:
                csvfile = csv.writer(f_once)
                csvfile.writerow(fieldnames)
            do_once = False

        # Now, append all orignal CSV data to this file
        with open(new_filename, 'a') as f_new:
            csvfile = csv.writer(f_new)
            for line in self.yield_csv_data(single_csv):
                csvfile.writerow(line)

    # Finally, dedupe the consolidated file
    # TODO: ERRORS - Need to make pandas treat the codes columns as strings, not convert to floats
    #deduped_file = dedupe_csv_pandas(new_filename)

    # We now have a new file that has written data from all of our files in the files list
    print(f"[*] Consolidated from {len(self.parent_dir_list):,d} original files for filename: {csv_filename}")
    log.debug(f"Consolidated/Merged CSV file has been written and saved to: {new_filename}")
    return



# --------- Custom CSV Big Data File Writer / Reader -----------
# - Ref: https://dzone.com/articles/splitting-csv-files-in-python


def split_massive_csv(csv_file, target_row_size=100000, fieldnames=None):
    """ Helper to take an input CSV file and split it up into smaller,
        manageable files based on a max row size param.

    Usage:
    rows_per_file = 5000000
    split_massive_csv(sys.argv[1], target_row_size=rows_per_file)

    """
    print("[*] Analyzing input file for split operation...")
    delim = ','
    current_number_lines = sum(1 for row in (open(csv_file)))
    # pandas way of getting line count
    #df = pd.read_csv(csv_file, header=0)
    #current_number_lines = len(df.index) + 1

    #target_row_size = 100000

    # Calculate approx how many output files this translates to
    approx_num_files = round(current_number_lines / target_row_size)
    print(f"[*] This split operation will result in {approx_num_files} output files")

    # None for infinite, otherwise max output files before stopping
    max_num_files = 20

    # fieldnames = [
    #     "root_hash",
    #     "reporting_entity_name",
    #     "reporting_entity_type",
    #     "plan_name",
    #     "plan_id",
    #     "plan_id_type",
    #     "plan_market_type",
    #     "last_updated_on",
    #     "version",
    #     "filename",
    #     "url",
    # ]

    # Could also get header based on existing CSV file
    if not fieldnames:
        with open(csv_file, 'r') as f:
            fieldnames = f.readline()
        fieldnames = fieldnames.split(",")
        fieldnames = [x.strip() for x in fieldnames]

    log.debug("fieldnames have been loaded from input file")
    log.debug(fieldnames)
    #print(fieldnames)

    if not fieldnames:
        fieldnames = False

    file_path = Path(csv_file).resolve(strict=True).parent
    # Read in the data, x rows per iteration
    counter = 0
    for i in range(0, current_number_lines, target_row_size):
        df = pd.read_csv(
            csv_file,
            sep=delim,
            nrows=target_row_size,
            skiprows=i
        )
        df.columns = fieldnames

        # The CSV output file names
        counter += 1
        csv_output_file = file_path / f"{str(Path(csv_file).stem)}_{str(counter)}.csv"

        # Write x rows to file each iteration
        df.to_csv(
            csv_output_file,
            index=False,
            header=True,
            #mode='a',
            chunksize=target_row_size
        )

        # if max_num_files and (counter >= max_num_files):
        #     break
    log.info("Finished writing all split CSVs from the original, enjoy!")
    return




def split_csv_faster():
    # NOE: This approach is faster, jsut not as robust as pandas
    target_row_size = 100000
    chunk_size = target_row_size
    def write_chunk(part, lines):
        with open('../tmp/split_csv_python/data_part_'+ str(part) +'.csv', 'w') as f_out:
            f_out.write(header)
            f_out.writelines(lines)

    with open("../nyc-parking-tickets/Parking_Violations_Issued_-_Fiscal_Year_2015.csv", "r") as f:
        count = 0
        header = f.readline()
        lines = []
        for line in f:
            count += 1
            lines.append(line)
            if count % chunk_size == 0:
                write_chunk(count // chunk_size, lines)
                lines = []
        # write remainder
        if len(lines) > 0:
            write_chunk((count // chunk_size) + 1, lines)







# ----------------------
#   JSON Helpers
# ----------------------


def beautify_json(obj) -> str:
    return "\n" + json.dumps(obj, sort_keys=True, indent=4, separators=(",", ": "))








# ----------------------
#   Zipfile Helpers
# ----------------------

def download_zip_file(url, destination=None):
    """ Download and extract a zip file. """
    if not destination:
        destination = DOWNLOADS_DIR

    if not os.path.isdir(destination):
        os.makedirs(destination)

    with urlopen(url) as zipres:
        with ZipFile(BytesIO(zipres.read())) as zfile:
            # If zip is single file, this function should return the
            # full path to the extracted file
            fname = zfile.extractall(destination)

            log.debug(f"zipfile filelist: {zfile.filelist}")
            # ex: zipfile filelist: [<ZipInfo filename='2023-01-08_Health-Plans-Inc-(HPI)_index.json' compress_type=deflate filemode='-rwxrwxrwx' file_size=7347 compress_size=1044>]

            log.debug(f"zipfile namelist: {zfile.namelist()}")
            # ex: zipfile namelist: ['2023-01-08_Health-Plans-Inc-(HPI)_index.json']

            files_in_zip = zfile.namelist()

    files_list = [os.path.join(destination, x) for x in files_in_zip]
    log.debug(f"Fetched zip and its extracted files are being returned: {files_list}")
    return files_list



def zip_scan_folder(scan_folder: str):
    zip_file_path = f"{scan_folder}.zip"

    log.info(f"Compressing scan folder {scan_folder} to {zip_file_path}...")
    with zipfile.ZipFile(
        zip_file_path, "w", compresslevel=9, compression=zipfile.ZIP_DEFLATED
    ) as zf:
        for dirname, _, files in os.walk(scan_folder):
            zf.write(dirname)
            for filename in files:
                zf.write(os.path.join(dirname, filename))

    return zip_file_path


def list_files_from_zip(input_zip_url):
    """
    Check index parser class for an example of using this.
    """
    # Build destination path
    filename = download_file(input_zip_url)
    dest_dir = Path(__file__).resolve(strict=True).parent
    dest_file = dest_dir / filename

    # First, let's see if we can extract the zip w/o having to download it
    try:
        with urlopen(input_zip_url) as zipres:
            with ZipFile(BytesIO(zipres.read())) as zfile:
                zfile.extractall(dest_dir)
        # If successful, next we need to get a list of the extracted files
        files_list = glob.glob(os.path.join(self.output_dir, '*.csv'))

        return files_list

    except Exception as e:
        log.error(f"Error extracting zip on-the-fly - URL: {input_zip_url} - Error: {e}")
        pass

    try:
        download_file(index_loc, dest_file)
    except Exception as e:
        log.critical(e)
        log.error("Error fetching remote zip file, logged to errors and continuing")
        log.info(f"Failed download URL: {index_loc}")
        #with open(self.invalidmrfs_log_file, 'a') as f_invalids:
        #    f_invalids.write(f"{index_loc}\n")
        return

    if os.path.exists(dest_file):
        with ZipFile(dest_file, 'r') as zip_obj:
            zip_obj.extractall(dest_dir)
            files_list = zip_obj.namelist()
        log.info("Unzipped file succesfully")
        # So we can open it in next block, re-set the variable for it
        dest_file = dest_dir / f"{filename.replace('.zip', '.json')}"
        # as_posix converts it to string to it won't error inside JSONOpen
        index_loc = dest_file.as_posix()
        is_local = True
        log.info(f"Processing remote zip index file, is now local file at: {index_loc}")

    return files_list




# ----------------------
#   File/Dir Helpers
# ----------------------


def make_dir(out_dir):
    """ Make a dir. """
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)



def check_file_older_than_threshold(input_file, check_interval=3):
    """
    Check if provided file timestamp is older than 'x' days threshold. If so, return True.

    check_interval=0 ('n' days) just always returns True so if this is part of a workflow, you can always get new data.
    """
    # TODO: Move this to common.py file for general utilities

    date_threshold = datetime.datetime.now() - datetime.timedelta(days=int(check_interval))

    if check_interval == 0:
        return True

    if os.path.exists(input_file):
        # File already exists, check how old it is
        file_date = datetime.datetime.fromtimestamp(os.path.getmtime(input_file))
        log.debug(f"file_date is {file_date}")
        if file_date < date_threshold:
            log.debug("File is older than the desired threshold, returning True")
            return True
        else:
            return False
    else:
        # File doesn't exist, return True just like we need new data
        return True


def get_file_suffix(fname):
    """ Get accurate/complete file suffix from provided filename. """
    if isinstance(fname, str):
        fname = Path(fname)
    suf = fname.suffixes
    if len(suf) > 1:
        # File is a multi-extension (e.g. ".tar.gz") and requires more code for an accurate match
        real_suffix = '.'.join([x.lower() for x in suf])
    elif len(suf) == 1:
        real_suffix = fname.suffix.lower()
    else:
        #logger.debug("File with no extension: {}".format(fname))
        pass
    return real_suffix

