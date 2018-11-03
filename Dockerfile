ARG CPU_CORE=4
ARG KUI=200

FROM dockerhub.iis.sinica.edu.tw/siann1-hak8_boo5-hing5:${KUI} as tsuliau

FROM dockerhub.iis.sinica.edu.tw/liau-kaldi

MAINTAINER sih4sing5hong5

ENV SIANN_KALDI_S5C /usr/local/kaldi/egs/taiwanese/s5c
ENV KALDI_S5C /usr/local/kaldi/egs/formosa/s5
RUN mkdir -p $KALDI_S5C
WORKDIR $KALDI_S5C

COPY --from=tsuliau /usr/local/pian7sik4_gi2liau7/ /usr/local/pian7sik4_gi2liau7/
COPY --from=tsuliau $SIANN_KALDI_S5C/data $KALDI_S5C/data
COPY --from=tsuliau $SIANN_KALDI_S5C/cmd.sh $KALDI_S5C

RUN mkdir -p $SIANN_KALDI_S5C/
RUN ln -s $KALDI_S5C/data $SIANN_KALDI_S5C/data

ENV LANG en_US.UTF-8

RUN mkdir -p /usr/local/gi2_liau7_khoo3
RUN ln -s /usr/local/pian7sik4_gi2liau7/twisas/音檔 /usr/local/gi2_liau7_khoo3

RUN ln -s lang_train data/lang

ARG CPU_CORE
RUN sed 's/16000/8000/g' -i conf/*.conf
RUN sed 's/-r 16k/-r 8k/g' -i data/*/wav.scp
COPY run.sh .
RUN bash -x run.sh --num_jobs ${CPU_CORE}

COPY --from=dockerhub.iis.sinica.edu.tw/2017nithau /home/johndoe/git/Ko-Ming-Tat_2015_TAIWANESE-SPEECH-AND-TEXT-CORPUS/資料庫影音檔案 /home/johndoe/git/Ko-Ming-Tat_2015_TAIWANESE-SPEECH-AND-TEXT-CORPUS/資料庫影音檔案
COPY --from=dockerhub.iis.sinica.edu.tw/2017nithau /s5c-demo /s5c

COPY 2017nithau.sh .
RUN bash -x 2017nithau.sh --stage -1
RUN bash -x 2017nithau.sh --stage 2
#RUN bash -x 2017nithau.sh --stage 5
RUN bash -x 2017nithau.sh --stage 16
RUN rm data/lang
RUN ln -s lang_2017 data/lang

COPY ivector_diff .
RUN git apply ivector_diff
RUN bash -x local/nnet3/run_ivector_common.sh --test_sets train_dev

RUN ln -s train data/train_sp
RUN sed 's/-le/-eq/g' local/chain/run_tdnn.sh -i
RUN bash -x local/chain/run_tdnn.sh --stage 7
RUN bash -x local/chain/run_tdnn.sh --stage 8
RUN bash -x local/chain/run_tdnn.sh --stage 9

RUN wget -O local/chain/run_tdnnf.sh https://github.com/sih4sing5hong5/kaldi/raw/taiwanese-liau-tdnnf/egs/taiwanese/s5c/liau_run_tdnn.sh # 20181029-1921
RUN sed -i 's/ -le / -eq /g' local/chain/run_tdnnf.sh
RUN bash -x local/chain/run_tdnnf.sh --stage 10
CMD bash -x local/chain/run_tdnnf.sh --stage 11

#RUN sed 's/in test/in train_dev/g' local/chain/run_tdnn.sh -i
#RUN bash -x local/chain/run_tdnn.sh --stage 12
#RUN bash -x local/chain/run_tdnn.sh --stage 13

