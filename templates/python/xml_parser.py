

from contextlib import ContextDecorator

import xmltodict



class XmlParser(ContextDecorator):
    """ This is mostly based off WitnessMe's parsers.py file. 

        In this format, it's meant to be a parser to read an input xml and build a list of targets.
    
    
    """
    def __init__(self, file_path):
        self.xml_file_path = file_path
        self.item_depth = 4
        self.https_ports = [443, 8443]
        self.http_ports = [80, 8080]
        self.urls = set()
    
    def parser_callback(self, path, item):
        return True
    
    def __enter__(self):
        with open(self.xml_file_path, "rb") as xml_file_path:
            try:
                xmltodict.parse(
                    xml_file_path,
                    item_depth=self.item_depth,
                    item_callback=self.parser_callback,
                    process_namespaces=True,
                )
            except ExpatError as e:
                log.error(e)

            for url in self.urls:
                yield url

    def __exit__(self, *exc):
        self.urls = set()



class XmlMrfParser(XmlParser):
    # As of right now, we aren't seeing anything like this.
    pass