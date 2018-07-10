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
COPY --from=siann /usr/local/pian7sik4_gi2liau7/ /usr/local/pian7sik4_gi2liau7/
COPY --from=siann $KALDI_S5C/data $KALDI_S5C/data
COPY --from=siann $KALDI_S5C/exp $KALDI_S5C/exp
COPY --from=siann $KALDI_S5C/local $KALDI_S5C/local
COPY --from=siann $KALDI_S5C/cmd.sh $KALDI_S5C
COPY --from=siann $KALDI_S5C/path.sh $KALDI_S5C
RUN ln -s ../../wsj/s5/steps steps
RUN ln -s ../../wsj/s5/utils utils
RUN apt-get install -y sox
#COPY --from=siann $KALDI_S5C/conf $KALDI_S5C/conf
#RUN sed 's/8000/16000/g' -i conf/mfcc_hires.conf
RUN mkdir conf
RUN cp ../../wsj/s5/conf/mfcc_hires.conf conf/
RUN cp ../../wsj/s5/conf/online_cmvn.conf conf/
COPY run_ivector_common.sh run_ivector_common.sh
RUN bash -x run_ivector_common.sh
COPY run_tdnn_1f.sh run_tdnn_1f.sh
RUN bash -x run_tdnn_1f.sh
