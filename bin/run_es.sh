#!/bin/bash

docker run -p 9200:9200 -p 9300:9300 \
           -v elasticsearch:/usr/share/elasticsearch/data \
           -e "discovery.type=single-node" \
           docker.elastic.co/elasticsearch/elasticsearch:6.3.2
