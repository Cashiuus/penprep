


from contextlib import ContextDecorator
from pathlib import Path

import pandas as pd



class TargetsBuilder(object):
    """
    Generate targets as an input list to a workflow.
    """
    





class TargetFormatter(ContextDecorator):
    """ Generate me some targets as a generator.
        
    """
    def __init__(self, targets):
        self.targets = targets
    
    def generate(self, targets):

        if Path(targets).exists():
            if targets.lower().endswith('db'):
                input_loader = DBFileInputLoader()


    def __enter__(self):
        if self.target.startswith("http"):
            yield self.target
    
    def __exit__(self, *exc):
        pass


