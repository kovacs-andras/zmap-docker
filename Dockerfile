FROM alpine:latest

LABEL maintainer "andras0602@hotmail.com"

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

RUN apk add --no-cache \
    gmp-dev \
    json-c-dev \
    libunistring-dev \
    libcap \
    libpcap \
    tini

RUN apk add --no-cache --virtual .build-deps \
    byacc \
    cmake \
    flex \
    g++ \
    gengetopt \
    git \
    libpcap-dev \
    linux-headers \
    make \
 && ln -s /usr/bin/yacc /usr/bin/byacc \
 && git clone https://github.com/zmap/zmap.git \
 && cd zmap \
 && cmake . \
 && make -j $(nproc) \
 && make install \
 # cleanup 
 && apk del .build-deps \
 && rm -vrf ../zmap /var/cache/apk/*

# Allow the use of raw sockets without root:
RUN setcap cap_net_raw=eip /usr/local/sbin/zmap \
# Plus allow private network ranges:
 && sed  -e "/RFC1918/ s/^/#/g" -i /etc/zmap/blacklist.conf

RUN adduser zmap -D -s /bin/false

USER zmap

ENTRYPOINT ["/sbin/tini", "/usr/local/sbin/zmap"]

CMD ["--help"]
