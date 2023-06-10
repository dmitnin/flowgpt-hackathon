#!/usr/bin/env python
import json

import requests
from bs4 import BeautifulSoup


def extract_links_recursive(base_url, url, links):
    response = requests.get(url)
    soup = BeautifulSoup(response.text, "html.parser")

    for link in soup.findAll('a'):
        href = link.get('href')

        if href is None:
            continue
        elif href.startswith('http'):
            absolute_url = href
        elif href.startswith('www'):
            absolute_url = 'https://' + href
        else:
            absolute_url = base_url + href

        def _filter(ref) -> bool:
            forbidden_chars = ['#', '..', '///', 'github']
            return not any(char in ref for char in forbidden_chars)

        if absolute_url.startswith(base_url) and _filter(absolute_url) and absolute_url not in links:
            links.append(absolute_url)
            print(absolute_url)
            links = extract_links_recursive(base_url, absolute_url, links)

    return links


url = 'https://gpt-index.readthedocs.io/en/latest/'
links = extract_links_recursive(url, url, [])

counts = dict()
for l in links:
    counts[l] = counts.get(l, 0) + 1

print(links)
with open('../docs/llama_index/links.json', 'w') as f:
    json.dump(counts, f)
