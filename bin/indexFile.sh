#!/bin/sh
# Use > 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use > 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
# note: if this is set to > 0 the /etc/hosts part is not recognized ( may be a bug )
while [[ $# > 1 ]]
do
key="$1"

case $key in
    -f|--file)
    FILE="$2"
    shift # past argument
    ;;
    -i|--id)
    ID="$2"
    shift # past argument
    ;;
    *)
          # unknown option
    ;;
esac
shift # past argument or value
done

echo FILE = "${FILE}"
echo ID = "${ID}"
fileName=`basename "${FILE}"`

coded=`cat "${FILE}" | perl -MMIME::Base64 -ne 'print encode_base64($_)'`
json="{\"isEnabled\" : true, \"filename\" : \"${fileName}\", \"data\" : \"${coded}\" }"
echo "$json" > json.file
#curl -X PUT "http://localhost:9200/policies/policy/${ID}?pipeline=attachment&refresh=true&pretty=1" -u user:password -d @json.file  # use this when using shield
curl -X PUT "http://127.0.0.1:9200/policies/policy/${ID}?pipeline=attachment&refresh=true&pretty=1" -d @json.file
