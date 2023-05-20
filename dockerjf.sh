#!/bin/bash
docker-compose up -d
docker exec -u 0 -it jellyfin sed -i 's/enableBackdrops:function(){return\ P}/enableBackdrops:function(){return\ _}/g' /jellyfin/jellyfin-web/main.jellyfin.bundle.js
