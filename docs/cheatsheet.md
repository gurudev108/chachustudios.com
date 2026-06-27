# 1. SRS (RTMP → HLS, serves srv/tv)
docker run --rm -it -p 1935:1935 -p 1985:1985 -p 8080:8080 \
  -v .../srv/tv:/usr/local/srs/objs/nginx/html ossrs/srs:6

# 2. Tunnel (tv.chachustudios.com → localhost:8080)
cloudflared tunnel run ...

# 3. Stream content (hourly loop or live)
./cs-hourly-live.sh          # pre-recorded, top of hour
./cs-live                    # live camera/mic via chachustudios-morning-stream.sh
