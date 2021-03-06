# Dockerfile for FileShelter (https://github.com/epoupon/fileshelter)

# Define base image and maintainer
FROM debian:stretch-slim
LABEL maintainer "Dylan Ratcliffe (https://github.com/dylanratcliffe)" \
      fileshelter_version "latest"

# Ser Dockerfile arguments
ARG fileshelter_src_url="https://github.com/epoupon/fileshelter.git"
ARG fileshelter_src_folder="fileshelter-latest"
ARG container_user="fileshelter"
ARG app_dir="/var/fileshelter"
ARG web_dir="/usr/share/fileshelter/"
ARG build_packages="autoconf automake build-essential ca-certificates git"

# Create unprivileged group and user
RUN groupadd -r "$container_user" -g 1000 \
    && useradd -u 1000 -r -g "$container_user" "$container_user"

# Install libraries / dependencies
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
      libboost-dev \
      libwtdbosqlite-dev \
      libwthttp-dev \
      libwtdbo-dev \
      libwt-dev \
      libconfig++-dev \
      libzip-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy project repository to container and install FileShelter
WORKDIR "$app_dir"

# Build Fileshelter application
RUN apt-get update \
    && apt-get -y install --no-install-recommends $build_packages \
    && git clone "$fileshelter_src_url" "$fileshelter_src_folder" \
    && cd "$fileshelter_src_folder" \
    && autoreconf -vfi \
    && ./configure --prefix=/usr --sysconfdir=/etc \
    && make install clean \
    && cd ../ \
    && rm -rf "${app_dir}/${fileshelter_src_folder}/" \
    # Clean up and prune image
    && apt-get -y purge --auto-remove $build_packages \
    && rm -rf /var/lib/apt/lists/* \
    # Assign app directory ownership to unprivileged user
    && chown -R "$container_user":"$container_user" "$app_dir" "$web_dir"

# Run application
VOLUME "$app_dir"
EXPOSE 5091
USER "$container_user"
ENTRYPOINT ["/usr/bin/fileshelter"]
