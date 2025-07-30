
import gzip
import io
import logging
import os
from pathlib import Path
from urllib.parse import urlencode, urlparse

import ijson
import requests

#from helpers import *
from schema import SCHEMA

#from seek import ffwd_cy

log = logging.getLogger("questengine.framework.parsers.json_parser")


# Right now this only works with python 3.9
try:
	assert ijson.backend == 'yajl2_c'
except AssertionError:
	raise Exception('Extremely slow without the yajl2_c backend')



class InvalidMRF(Exception):
	pass


class JSONOpen(io.BufferedIOBase):
	"""
	Context manager for opening JSON (.json.gz) MRFs.
	Handles local and remote gzipped and unzipped
	JSON files.
	"""

	def __init__(self, input):
		if type(input) == bytes:
			self.data = input
			self.loc = None
		else:
			self.loc = input
			self.data = None

		self.f = None
		self.r = None
		self.is_remote = None

		if self.loc:
			parsed_url = urlparse(self.loc)
			# @Cashiuus - 20221231 - Catch for bad filenames that contain text that gets parsed as a suffix
			#self.suffix = ''.join(Path(parsed_url.path).suffixes)
			self.suffix = ''.join([x for x in Path(parsed_url.path).suffixes if "(" not in x])
			self.suffix = self.suffix.replace("..", ".")

			if self.suffix not in ('.json.gz', '.json', '.zip'):		# @Cashiuus 20230101 - add .zip
				log.debug(f"Suffix is: {self.suffix}")
				raise InvalidMRF(f'Suffix not JSON: {self.loc}')

			self.is_remote = parsed_url.scheme in ('http', 'https')

	def __enter__(self):
		if self.data:
			self.f = io.BytesIO(self.data)
			return self.f
		if (
			self.is_remote
			and self.suffix == '.json.gz'
		):
			self.r = requests.get(self.loc, stream=True)
			#self.r = requests.get(urlencode(self.loc), stream=True)		# @Cashiuus - 20230101 - urlencode it
			self.f = gzip.GzipFile(fileobj=self.r.raw)

		elif (
			self.is_remote
			and self.suffix == '.json'
		):
			self.r = requests.get(self.loc, stream=True)
			#self.r = requests.get(urlencode(self.loc), stream=True)		# @Cashiuus - 20230101 - urlencode it
			self.r.raw.decode_content = True
			self.f = self.r.raw
		
		elif (
			self.is_remote
			and self.suffix == '.zip'
		):
			raise InvalidMRF(f'Zip file not yet solutioned: {self.loc}')	# @Cashiuus - 20230101 - draft for handling zip files

		elif self.suffix == '.json.gz':
			self.f = gzip.open(self.loc, 'rb')

		else:
			self.f = open(self.loc, 'rb')

		log.info(f'Successfully opened file: {self.loc}')
		return self.f

	def __exit__(self, exc_type, exc_val, exc_tb):
		if self.r and self.is_remote:
			self.r.close()

		self.f.close()
