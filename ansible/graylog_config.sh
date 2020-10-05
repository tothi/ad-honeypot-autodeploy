#!/bin/bash
#
# create Graylog lookup table (using previously created adapter + caches) by API calls
#

USER="$1"
PASS="$2"

ADAPTER=`/usr/bin/curl -s -H 'Content-Type: application/json' -H 'X-Requested-By: cli' http://${USER}:${PASS}@127.0.0.1:9000/api/system/lookup/adapters | /usr/bin/jq '.data_adapters[] | select(.name=="geoip")' | /usr/bin/jq -r '.id'`
CACHE=`/usr/bin/curl -s -H 'Content-Type: application/json' -H 'X-Requested-By: cli' http://${USER}:${PASS}@127.0.0.1:9000/api/system/lookup/caches | /usr/bin/jq '.caches[] | select(.name=="geoip")' | /usr/bin/jq -r '.id'`

/usr/bin/curl -s -H 'Content-Type: application/json' -H 'X-Requested-By: cli' "http://${USER}:${PASS}@127.0.0.1:9000/api/system/lookup/tables" -X POST --data "{\"title\":\"GeoIP\",\"description\":\"GeoIP Lookup Table\",\"name\":\"geoip\",\"cache_id\":\"${CACHE}\",\"data_adapter_id\":\"${ADAPTER}\",\"content_pack\":null,\"default_single_value\":\"\",\"default_single_value_type\":\"NULL\",\"default_multi_value\":\"\",\"default_multi_value_type\":\"NULL\"}}"

/usr/bin/curl -s -H 'Content-Type: application/json' -H 'X-Requested-By: cli' "http://${USER}:${PASS}@127.0.0.1:9000/api/system/pipelines/rule" -X POST --data '{"title":"GeoIP lookup: IpAddress","description":"","source":"rule \"GeoIP lookup: IpAddress\"\nwhen\n  has_field(\"IpAddress\")\nthen\nlet geo = lookup(\"geoip\", to_string($message.IpAddress));\nset_field(\"IpAddress_geo_location\", geo[\"coordinates\"]);\nset_field(\"IpAddress_geo_country\", geo[\"country\"].iso_code);\nset_field(\"IpAddress_geo_city\", geo[\"city\"].names.en);\nend\n"}'

/usr/bin/curl -s -H 'Content-Type: application/json' -H 'X-Requested-By: cli' "http://${USER}:${PASS}@127.0.0.1:9000/api/system/pipelines/pipeline" -X POST --data '{"title":"GeoIP lookup","description":"","source":"pipeline \"GeoIP lookup\"\nstage 0 match either\nrule \"GeoIP lookup: IpAddress\"\nend","stages":[{"stage":0,"match_all":false,"rules":["GeoIP lookup: IpAddress"]}]}'

/usr/bin/curl -s -H 'Content-Type: application/json' -H 'X-Requested-By: cli' "http://${USER}:${PASS}@127.0.0.1:9000/api/system/pipelines/pipeline"

PIPELINE=`/usr/bin/curl -s -H 'Content-Type: application/json' -H 'X-Requested-By: cli' "http://${USER}:${PASS}@127.0.0.1:9000/api/system/pipelines/pipeline" | /usr/bin/jq '.[] | select(.title=="GeoIP lookup")' | /usr/bin/jq -r '.id'`
STREAM="000000000000000000000001"

/usr/bin/curl -s -H 'Content-Type: application/json' -H 'X-Requested-By: cli' "http://${USER}:${PASS}@127.0.0.1:9000/api/system/pipelines/connections/to_stream" -X POST --data "{\"stream_id\":\"${STREAM}\",\"pipeline_ids\":[\"${PIPELINE}\"]}"

/usr/bin/curl -s -H 'Content-Type: application/json' -H 'X-Requested-By: cli' "http://${USER}:${PASS}@127.0.0.1:9000/api/system/content_packs" -X POST -d @/home/ubuntu/dashboard.json

/usr/bin/curl -s -H 'Content-Type: application/json' -H 'X-Requested-By: cli' "http://${USER}:${PASS}@127.0.0.1:9000/api/system/content_packs/2397d589-a1fd-4ad8-b271-e72f44b4611f/1/installations" -X POST -d '{"parameters": {}, "comment": ""}'
