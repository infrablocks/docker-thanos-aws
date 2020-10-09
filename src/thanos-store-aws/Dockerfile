ARG BASE_IMAGE_VERSION
FROM infrablocks/thanos-aws:$BASE_IMAGE_VERSION

COPY start.sh /opt/thanos/bin/store-start.sh

RUN chmod +x /opt/thanos/bin/store-start.sh

ENV STARTUP_SCRIPT_PATH=/opt/thanos/bin/store-start.sh
