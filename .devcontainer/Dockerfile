FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gpg \
    cmake \
    ninja-build \
    gfortran \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO- \
    https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
    | gpg --dearmor \
    > /usr/share/keyrings/oneapi-archive-keyring.gpg \
    && echo \
    "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
    > /etc/apt/sources.list.d/oneAPI.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    intel-oneapi-compiler-fortran \
    intel-oneapi-mkl-devel \
    && rm -rf /var/lib/apt/lists/*

RUN echo 'source /opt/intel/oneapi/setvars.sh >/dev/null 2>&1' >> /etc/bash.bashrc

RUN pip3 install --break-system-packages fortls