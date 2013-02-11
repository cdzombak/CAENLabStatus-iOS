#!/usr/bin/python

import requests
import json

r = requests.get('http://api.engin.umich.edu/hostinfo/v1/computers.json?building=PIERPONT&room=B505')

if r.status_code is not 200:
	print("Invalid status code " + r.status_code + " received")
	exit(1)

hosts = json.loads(r.text)
hosts_used = 0

for host in hosts:
	print(host['hostname'])
	if host['in_use']:
		hosts_used = hosts_used + 1

print ("")
print("hosts: " + str(len(hosts)))
print ("used: " + str(hosts_used))
