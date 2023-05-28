#!/bin/bash
sleep 900
name=$1
HASH=$2
category=$3
location=/data/torrents

if [[ -z "$category" ]]; then
  echo "No category"
  exit
fi

if [[ "$category" == "readarr" ]]; then
  echo "Not working for readarr"
  exit
fi

case $category in
  radarr)
    moviename=$(echo "$name" | sed -e 's/ /%20/g')
    location=$(curl -i -X 'GET' "http://radarr:7878/radarr/api/v3/movie/lookup?term="$moviename"&apikey=" -H 'accept: */*' | grep \"path\" | awk 'BEGIN { FS = ": " } ; { print $2 }' | cut -f1 -d"," | sed '1p;d')
    echo $moviename
    echo $location
    ;;
  sonarr)
    seriesname=$(echo "$name" | sed -e 's/ /%20/g')
    location=$(curl -i -X 'GET' "http://sonarr:8989/sonarr/api/v3/series/lookup?term="$seriesname"&apikey=" -H 'accept: */*' | grep \"path\" | awk 'BEGIN { FS = ": " } ; { print $2 }' | cut -f1 -d"," | sed '1p;d')
    echo $seriesname
    echo $location
    ;;
  *)
    echo "Category other than radarr or sonarr"
    exit
    ;;
esac

curl -i -c /data/torrents/cookie.txt --header "Referer: http://localhost:8080" --data "username=&password=" http://localhost:8080/api/v2/auth/login
sid=$(grep 'SID' /data/torrents/cookie.txt | awk '{print $7}')
#echo "Login, cookie: "$sid"" > /data/torrents/debugmove

location=$(echo "$location" | sed 's/"//g')

if [ ! -d "$location" ]; then
  echo "Dir does not exist." > /data/torrents/nodir
  exit
fi

location=$(echo "$location" | sed -e 's/ /%20/g')

echo "Cookie: SID="$sid""
echo "hashes="$HASH"&location="$location""
#size=$(printf "%s" "hashes="$HASH"&location="$location"" | wc -c)
#echo $size
echo "Location "$location""
echo "HASH: "$HASH""
#location=/data/torrents
#echo "curl --http1.1 -i -H "User-Agent: Fiddler" -H "Host: 127.0.0.1" -H "Cookie: SID="$sid"" -H "Content-Type: application/x-www-form-urlencoded" http://localhost:8080/api/v2/torrents/setLocation --data "hashes="$HASH"\&location="$location"""
curl --http1.1 -i -H "User-Agent: Fiddler" -H "Host: 127.0.0.1" -H "Cookie: SID="$sid"" -H "Content-Type: application/x-www-form-urlencoded" http://localhost:8080/api/v2/torrents/setLocation --data "hashes="$HASH"&location="$location"" > /data/torrents/status
#echo "Set location, sent" > /data/torrents/debug2
response=$(cat /data/torrents/status | awk '/^HTTP/{print $2}')
sleep 600
echo "$response"
if [ $response = "200" ]; then
  echo "Response: Ok. Removing original file..."
  rm /data/torrents/"$name"
fi
