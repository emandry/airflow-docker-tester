FROM alpine:3.18

RUN echo https://dl-cdn.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories
RUN echo https://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories

ENV TZ=UTC

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
        geos 
        
RUN apk add --no-cache libc++ libc++-dev re2-dev re2 geos-dev
RUN apk update && apk upgrade

RUN pip3 install --no-cache-dir cython wheel pytest flake8 --break-system-packages
RUN pip3 install --no-cache-dir pytest-black numpy datetime geos --break-system-packages
RUN pip3 install --no-cache-dir apache-airflow[google] --break-system-packages

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh 

WORKDIR /airflow

RUN mkdir /airflow/variables

#ENTRYPOINT ["/entrypoint.sh"]


