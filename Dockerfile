FROM alpine:3.18

RUN echo https://dl-cdn.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories
RUN echo https://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories

ENV TZ=UTC
RUN apk update && apk upgrade
RUN apk add --no-cache \
        build-base \
        cmake \
        py3-pip \
        python3-dev \
        gcc \
        musl-dev \
        libffi-dev \ 
        linux-headers \
        g++ \
        apache-arrow \
        py3-pyarrow \
        py3-arrow \
        py3-grpcio \
        bash \
        py3-pybind11 \
        py3-pybind11-dev \
        py3-virtualenv \
        geos wget libc++ libc++-dev re2-dev re2 geos-dev ca-certificates
        
#RUN apk add --no-cache wget libc++ libc++-dev re2-dev re2 geos-dev ca-certificates


## Add Certificate Validation and consul
RUN update-ca-certificates

RUN pip3 install --no-cache-dir cython wheel pytest --break-system-packages
RUN pip3 install --no-cache-dir numpy datetime geos --break-system-packages
RUN pip3 install --no-cache-dir apache-airflow[google,cncf.kubernetes] --break-system-packages

RUN mkdir /entrypoint
COPY consul/* /entrypoint

ARG CONSUL_TEMPLATE_VERSION=0.35.0
RUN cd /entrypoint && wget "https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip" && \
  unzip consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip && \
  rm -f consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip
  

COPY entrypoint.sh /entrypoint
RUN mkdir /root/airflow && mkdir /airflow
COPY airflow.cfg /root/airflow
RUN chmod +x /entrypoint/entrypoint.sh 

WORKDIR /airflow

ENTRYPOINT ["/entrypoint/entrypoint.sh"]


