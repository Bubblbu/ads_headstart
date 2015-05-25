from __future__ import print_function, division
import pandas as pd

import requests
import logging
import re
import time

import threading
import Queue

old_arxiv_format = re.compile(r'(?:ar[X|x]iv:)?([^\/]+\/\d+)(?:v\d+)?$')
new_arxiv_format = re.compile(r'(?:ar[X|x]iv:)?(\d{4}\.\d{4,5})(?:v\d+)?$')

# Enable HTTP Debugging with logger
import httplib as http_client
http_client.HTTPConnection.debuglevel = 1

# You must initialize logging, otherwise you'll not see debug output.
logging.basicConfig()
logging.getLogger().setLevel(logging.INFO)
requests_log = logging.getLogger("requests.packages.urllib3")
requests_log.setLevel(logging.INFO)
requests_log.propagate = True

__author__ = 'Asura Enkhbayar <aenkhbayar@know-center.at>'

# Configuration
num_threads = 10
cat = "cs_dl"

api_key = "yd6DF417X6BBlNYgNuamC7SsD4kMFpFPfKHSkhDh"
headers = {'Authorization': "Bearer:" + api_key}
adsws_url = "http://adsws-staging.elasticbeanstalk.com/v1/search/query/"


class ADSThread(threading.Thread):
    def __init__(self, input_q, output_q):
        threading.Thread.__init__(self)
        self.input_q = input_q
        self.output_q = output_q

    def run(self):
        while not self.input_q.empty():
            arxiv_id = self.input_q.get_nowait()
            payload = {'q': 'arxiv:{}'.format(arxiv_id), 'sort': 'read_count desc',
                       'fl': 'reader,title,abstract,year,author,pub,read_count,citation_count,identifier'}
            r = requests.get(adsws_url, params=payload, headers=headers)
            temp = r.json()['response']['docs'][0]
            temp['url'] = "http://arxiv.org/abs/" + arxiv_id
            try:
                temp['authors'] = ";".join(temp['author'])
                del temp['author']
            except KeyError:
                temp['authors'] = []

            if 'reader' not in temp:
                temp['reader'] = []

            temp['readers'] = int(temp['read_count'])
            temp['reader_ids'] = u";".join(temp['reader'])
            temp['title'] = temp['title'][0]

            del temp['read_count']
            del temp['reader']
            self.output_q.put(temp)

# Load files file - arxiv id's
ids = pd.read_json("../files/{}.json".format(cat))

input_queue = Queue.Queue()
output_queue = Queue.Queue()

for count, arxiv_id in enumerate(ids.id.tolist()):
    found_regex = new_arxiv_format.findall(arxiv_id)
    if found_regex:
        arxiv_id = found_regex[0]
    else:
        found_regex = old_arxiv_format.findall(arxiv_id)
        if found_regex:
            arxiv_id = found_regex[0]

    input_queue.put(arxiv_id)

threads = []
for i in range(num_threads):
    thread = ADSThread(input_queue, output_queue)
    thread.start()
    threads.append(thread)

for thread in threads:
    thread.join()

rows = []
while not output_queue.empty():
    rows.append(output_queue.get_nowait())

# Convert to pandas dataframe
df = pd.DataFrame(rows)

# Rename columns
df.rename(columns={'pub': 'published_in', 'abstract': 'paper_abstract'}, inplace=True)
df.index.name = "id"

# Output
df.to_csv("../files/{}_ads_data.csv".format(cat), encoding='utf8')
