FROM dockerhub.iis.sinica.edu.tw/huagi-8k

MAINTAINER sih4sing5hong5

COPY 4.wav /
COPY data data
COPY decode_nnet3.sh .
COPY 走評估nnet3.sh ./val_nnet3.sh

RUN bash -x val_nnet3.sh dd data/train || echo
RUN cat exp/chain/tdnn_1a_sp//decode_train_dev/log/decode.1.log

