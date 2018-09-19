ARG KUI
FROM nvidia/cuda:9.1-devel-ubuntu16.04 as kaldi

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
#RUN git clone https://github.com/kaldi-asr/kaldi.git
RUN git clone https://github.com/yfliao/kaldi.git


WORKDIR /usr/local/kaldi/tools
RUN extras/check_dependencies.sh
RUN make -j $CPU_CORE

WORKDIR /usr/local/kaldi/src
RUN ./configure && make depend -j $CPU_CORE && make -j $CPU_CORE

ENV KALDI_S5C /usr/local/kaldi/egs/formosa/s5

RUN mkdir -p $KALDI_S5C
WORKDIR $KALDI_S5C


FROM dockerhub.iis.sinica.edu.tw/siann1-hak8_boo5-hing5:${KUI} as tsuliau

FROM kaldi
ENV KALDI_S5C /usr/local/kaldi/egs/formosa/s5
ENV SIANN_KALDI_S5C /usr/local/kaldi/egs/taiwanese/s5c

COPY --from=tsuliau /usr/local/pian7sik4_gi2liau7/ /usr/local/pian7sik4_gi2liau7/
COPY --from=tsuliau $SIANN_KALDI_S5C/data $KALDI_S5C/data
COPY --from=tsuliau $SIANN_KALDI_S5C/cmd.sh $KALDI_S5C
#RUN ln -s ../../wsj/s5/steps steps
#RUN ln -s ../../wsj/s5/utils utils
RUN apt-get install -y sox
RUN apt-get install -y vim

RUN mkdir -p $SIANN_KALDI_S5C/
RUN ln -s $KALDI_S5C/data $SIANN_KALDI_S5C/data

ENV LANG en_US.UTF-8

RUN mkdir -p /usr/local/gi2_liau7_khoo3
RUN ln -s /usr/local/pian7sik4_gi2liau7/twisas/音檔 /usr/local/gi2_liau7_khoo3

RUN ln -s lang_train data/lang

RUN echo '--allow_downsample=true' >> conf/mfcc.conf
RUN echo '--allow_downsample=true' >> conf/mfcc_pitch.conf
RUN echo '--allow_downsample=true' >> conf/mfcc_hires.conf
RUN echo 's/16000/8000/g' -i conf/*.conf
COPY run.sh .
RUN bash -x run.sh --num_jobs ${CPU_CORE}

RUN bash -x local/nnet3/run_ivector_common.sh --test_sets train_dev

RUN ln -s train data/train_sp
RUN sed 's/-le/-eq/g' local/chain/run_tdnn.sh -i
RUN bash -x local/chain/run_tdnn.sh --stage 7
RUN bash -x local/chain/run_tdnn.sh --stage 8
RUN bash -x local/chain/run_tdnn.sh --stage 9
RUN bash -x local/chain/run_tdnn.sh --stage 10
CMD bash -x local/chain/run_tdnn.sh --stage 11

#RUN sed 's/in test/in train_dev/g' local/chain/run_tdnn.sh -i
#RUN bash -x local/chain/run_tdnn.sh --stage 12
#RUN bash -x local/chain/run_tdnn.sh --stage 13

