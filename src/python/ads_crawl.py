from __future__ import print_function, division
import requests
import logging
import numpy as np

import httplib as http_client
http_client.HTTPConnection.debuglevel = 1

# You must initialize logging, otherwise you'll not see debug output.
logging.basicConfig()
logging.getLogger().setLevel(logging.DEBUG)
requests_log = logging.getLogger("requests.packages.urllib3")
requests_log.setLevel(logging.DEBUG)
requests_log.propagate = True

__author__ = 'Asura Enkhbayar <aenkhbayar@know-center.at>'

api_key = "YcuYTsmIpTLorekgNfrI5PsuJF7QkNnbM1Sq9wQW"
headers = {'Authorization': "Bearer:" + api_key}
adsws_url = "http://adsws-staging.elasticbeanstalk.com/v1/search/query/"
adsabs_url = "https://ui.adsabs.harvard.edu/#search/"
no_js_url = "http://labs.adsabs.harvard.edu/adsabs/#search/"

payload = {'q': 'trending(bibcode:2014arXiv1407.3453F)', 'sort': 'read_count desc', 'fl': 'bibcode,read_count,reader'}

r = requests.get(adsws_url, params=payload, headers=headers)

r_json = r.json()

bibcodes = []
for doc in r_json['response']['docs']:
    bibcodes.append(doc['bibcode'])

readers = []
for bibcode in bibcodes:
    payload = {'q': 'bibcode:{}'.format(bibcode), 'sort': 'read_count desc', 'fl': 'reader'}
    r = requests.get(adsws_url, params=payload, headers=headers)

    readers.append(r.json()['response']['docs'][0]['reader'])

a = set([item for sublist in readers for item in sublist])
cooc = np.zeros((len(readers), len(readers)), dtype=int)
sum = 0
for idx1, list1 in enumerate(readers):
    sum += len(list1)
    for idx2, list2 in enumerate(readers):
        if idx2 > idx1:
            co_read = len(set(list1) & set(list2))

            cooc[idx2, idx1] = co_read
            cooc[idx1, idx2] = co_read
        elif idx1 == idx2:
            cooc[idx1, idx1] = len(set(readers[idx1]))

print("\nAbsolute values")
print(cooc)