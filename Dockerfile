ARG CPU_CORE=4
FROM nvidia/cuda:9.1-devel-ubuntu16.04 as kaldi

MAINTAINER sih4sing5hong5


RUN \
  apt-get update -qq && \
  apt-get install -y \
    git bzip2 wget \
    g++ make python python3 \
    zlib1g-dev automake autoconf libtool subversion \
    libatlas-base-dev \
    sox vim


WORKDIR /usr/local/
# Use the newest kaldi version
#RUN git clone https://github.com/kaldi-asr/kaldi.git
RUN git clone https://github.com/yfliao/kaldi.git
WORKDIR /usr/local/kaldi/
RUN git remote add kaldi https://github.com/kaldi-asr/kaldi.git
RUN git fetch kaldi
RUN git config --global user.name "fafoy" && \
  git config --global user.email fafoy@example.com
RUN git merge kaldi/master

ARG CPU_CORE
WORKDIR /usr/local/kaldi/tools
RUN extras/check_dependencies.sh
RUN make -j ${CPU_CORE}

WORKDIR /usr/local/kaldi/src
RUN ./configure && make depend -j ${CPU_CORE} && make -j ${CPU_CORE}


ENV KALDI_S5C /usr/local/kaldi/egs/formosa/s5
WORKDIR $KALDI_S5C


COPY liau/conf conf
COPY liau/exp exp

#ARG CPU_CORE
#RUN sed 's/16000/8000/g' -i conf/*.conf
#RUN sed 's/-r 16k/-r 8k/g' -i data/*/wav.scp
#CMD bash -x run.sh --num_jobs ${CPU_CORE}


