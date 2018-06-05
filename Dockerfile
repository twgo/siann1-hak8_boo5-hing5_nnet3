FROM nvidia/cuda:9.1-devel-ubuntu16.04

MAINTAINER sih4sing5hong5

ENV CPU_CORE 4

RUN \
  apt-get update -qq && \
  apt-get install -y \
    git bzip2 wget \
    g++ make python python3 \
    zlib1g-dev automake autoconf libtool subversion \
    libatlas-base-dev


WORKDIR /usr/local/
# Use the newest kaldi version
RUN git clone https://github.com/kaldi-asr/kaldi.git


WORKDIR /usr/local/kaldi/tools
RUN extras/check_dependencies.sh
RUN make -j $CPU_CORE

WORKDIR /usr/local/kaldi/src
RUN ./configure && make depend -j $CPU_CORE && make -j $CPU_CORE

ENV KALDI_S5C /usr/local/kaldi/egs/taiwanese/s5c

RUN mkdir -p $KALDI_S5C
WORKDIR $KALDI_S5C
COPY --from=siann $KALDI_S5C/data $KALDI_S5C/data
COPY --from=siann $KALDI_S5C/exp $KALDI_S5C/exp
COPY --from=siann $KALDI_S5C/local $KALDI_S5C/local
