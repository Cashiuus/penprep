from contextlib import ContextDecorator
from pathlib import Path

import pandas as pd

from targets import TargetFormatter



# TODO: Do I want these as openers, or just have them load file and cleanly build targets lists?
#   What if I build a class that builds the target lists, and it just uses these classes depending on input file type?


class DBFileInputLoader(ContextDecorator):
    def __init__(self, input_file):
        self.input_file = input_file

    def __enter__(self):
        pass

    def __exit_(self, *exc):
        pass



class CSVFileInputLoader(ContextDecorator):
    """ Load in a CSV file input. """
    def __init__(self, input_file):
        self.input_file = input_file

    
    def __enter__(self):
        # Read in the file to dataframe
        df = pd.read_csv(self.input_file)
        # Sort the input data, if able
        if "size" in df.columns:
            df = df.sort_values(by=["size"])
        # TODO: clean this up so it's only yielding a url
        # for url in df data:
            # yield url
    
    def __exit__(self, *exc):
        pass




class GenericFileInputLoader(ContextDecorator):
    def __init__(self, input_file):
        self.input_file = input_file
    
    def __enter__(self):
        with open(self.input_file, 'r') as f_read:
            for line in f_read:
                with TargetFormatter(line.strip()) as target_generator:
                    for url in target_generator:
                        yield url

    def __exit__(self, *exc):
        pass

