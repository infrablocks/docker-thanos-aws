FROM infrablocks/alpine-aws-s3-config:0.23.0-rc.7

ENV THANOS_VERSION 0.15.0

RUN apk \
    --verbose \
    --no-cache \
    add \
        su-exec \
        musl

RUN addgroup -S thanos && \
    adduser -S -G thanos thanos

RUN cd /tmp \
    && curl \
        -L "https://github.com/thanos-io/thanos/releases/download/v${THANOS_VERSION}/thanos-${THANOS_VERSION}.linux-amd64.tar.gz" \
        -o "thanos-${THANOS_VERSION}.linux-amd64.tar.gz" \
    && tar -xvf "thanos-${THANOS_VERSION}.linux-amd64.tar.gz" \
    && mkdir -p /opt/thanos \
    && cp -R "thanos-${THANOS_VERSION}.linux-amd64"/* /opt/thanos \
    && mkdir -p /opt/thanos/bin \
    && mkdir -p /opt/thanos/conf \
    && mv /opt/thanos/thanos /opt/thanos/bin/thanos \
    && rm "thanos-${THANOS_VERSION}.linux-amd64.tar.gz" \
    && rm -rf "thanos-${THANOS_VERSION}.linux-amd64" \
    && cd /

COPY start.sh /opt/thanos/bin/start.sh

RUN chmod +x /opt/thanos/bin/start.sh

RUN mkdir -p /var/opt/thanos \
    && chown -R thanos:thanos \
        /opt/thanos \
        /var/opt/thanos

ENV STARTUP_SCRIPT_PATH=/opt/thanos/bin/start.sh
