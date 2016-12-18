#!/usr/bin/env python
#
# Extract current version of CCleaner. If newer download
# and run installer in silent mode

import json
import os
import subprocess
import requests
from bs4 import BeautifulSoup as bs

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
SAVE_PATH = os.path.join(os.path.expandvars('%APPDATALOCAL%'), 'ccleaner')
SAVE_FILE = 'ccleaner_install.exe'
LOCAL_VERSION = '5.05.5176'
chunk_size = 1024

headers = {'User-Agent': 'Mozilla/5.0 (X11; U; Linux i686) Gecko/20071127 Firefox/2.0.0.11'}
url = 'https://www.piriform.com/ccleaner/download/standard'
url2 = 'http://www.filehippo.com/download_ccleaner'

bs_piriform_dict = {
	'id': 'BigDownload',
	}

bs_filehippo_dict = {
	'class': 'program-header-download-link-container',
	'class': 'program-header-download-link green button-link active long',
	}

# ------------------------------------------------------------------------------------

def soupify(url, headers=headers):
	"""
	Receive url and options, request the page, and process response into soup
	"""
	reqobj = requests.get(url, headers=headers)
	soup = bs(reqobj.content)
	return reqobj, soup


# First, get the current version release and compare to our local version string
def compare_versions():
	rv = requests.get(url2, headers=headers)
	soup = bs(rv.content)
	parseme = soup.title.string.split(' ')
	for elem in parseme:
		if elem.startswith('5'):
			# Save version string
			remote_version = elem
	
	print("[*] Current Version: {!s}".format(LOCAL_VERSION))
	print("[*] Newest Version: {!s}".format(remote_version))
	# Compare against each other to see if remote is newer
	if not LOCAL_VERSION == remote_version:
		# They are not equal strings, determine what is different
		remote_list = remote_version.split('.')
		local_list = LOCAL_VERSION.split('.')
		for i in local_list:
			j = remote_list[local_list.index(i)]
			if i != j:
				# If local version is less than remote version, newer exists
				if int(i) < int(j):
					# New version exists, must download it
					return True
			
	return False


def download_binary():
	r = requests.get(url, headers=headers)
	print(r.status_code)
	if r.status_code == 200:
		print('[*] Valid response, parsing page...')
		# Valid response, process page
		soup = bs(r.content)
		
		# Piriform Method
		for a in soup.find_all('div', bs_piriform_dict):
			#print(a)
			file_url = a.find('a').get('href')
			print('[*] Binary installer URL found: {}'.format(file_url))
		
		# Request the binary installer file
		r = requests.get(file_url, stream=True, headers=headers)
		local_filename = file_url.split('/')[-1]
		with open(SAVE_FILE, 'wb') as fd:
			for chunk in r.iter_content(chunk_size=chunk_size):
				fd.write(chunk)
		
		# Close the response object, streaming mode leaves it open
		r.close()
		print("[*] File saved successfully! Filename: {}".format(SAVE_FILE))
		exit(0)
		
		# Filehippo Pattern
		for a in soup.find_all('div', {'class': 'program-header-download-link-container '}):
			print(a.get('class'))
			for b in soup.find_all('a', {'class': 'program-header-download-link green button-link active long'}):
				file_url = b.get('href')
				print(file_url)
		# Now save the program
	return


def run_binary(binary_file):
	if os.path.isfile(binary_file):
		subprocess.call([binary_file, '/S'])
	return


if __name__ == '__main__':
	if compare_versions() is True:
		download_binary()
		run_binary(SAVE_FILE)
	else:
		print("[*] No new version at this time.")


#	ccsetup.exe /S			# Silent install with default options
#	ccsetup.exe /D=<path>	# Install into different directory than default
#	ccsetup.exe /L=<locale>	# Different language
# ------- CCLEANER USAGE OPTIONS --------------
#	ccleaner.exe /AUTO		# Run silently and automatically, using current set of saved options
#								AUTO does not run the registry cleaner
#	/SHUTDOWN				# Must precede with AUTO; Shutdown computer when done
#	/EXPORT					# Exports the cleaning rules to the INI files 
#								("winapp.ini, winreg.ini, winsys.ini")
#	/DELETE "path/to/file(s)"
#	/METHOD "0-3"			# Must be used with "DELETE" to specify how many passes
#		0 - 1 pass
#		1 - 3 passes
#		2 - 7 passes
#		3 - 35 passes