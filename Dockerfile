ARG ASF_VERSION

FROM justarchi/archisteamfarm:${ASF_VERSION}

RUN apt-get update && apt-get install -y git bash inotify-tools && apt-get clean

WORKDIR /app

COPY ./plugins /app/plugins
COPY ./scripts /app/scripts

RUN chmod -R +x /app/scripts

RUN mkdir -p /asf/config && cat <<EOF > /asf/config/IPC.config
{
  "Kestrel": {
    "Endpoints": {
      "HTTP": {
        "Url": "http://*:8000"
      }
    }
  }
}
EOF

ENTRYPOINT ["/app/scripts/sync.sh"]
