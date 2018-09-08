#!/bin/bash
#
# Copyright 2018, Yuan-Fu Liao, National Taipei University of Technology, yfliao@mail.ntut.edu.tw
#
# Before you run this recips, please apply, download and put or make a link of the corpus under this folder (folder name: "NER-Trs-Vol1").
# For more detail, please check:
# 1. Formosa Speech in the Wild (FSW) project (https://sites.google.com/speech.ntut.edu.tw/fsw/home/corpus)
# 2. Formosa Speech Recognition Challenge (FSW) 2018 (https://sites.google.com/speech.ntut.edu.tw/fsw/home/challenge)
stage=-2
num_jobs=4

# shell options
set -e -o pipefail

. ./cmd.sh
. ./utils/parse_options.sh

# tri5
if [ $stage -eq 5 ]; then

  echo "$0: train tri5 model"
  # Building a larger SAT system.
  ln -s ../exp/tri4 exp/tri5a

  # align tri5a
  steps/align_fmllr.sh --cmd "$train_cmd" --nj $num_jobs \
    data/train data/lang_train exp/tri5a exp/tri5a_ali || exit 1;


fi

# nnet3 tdnn models
# commented out by default, since the chain model is usually faster and better
#if [ $stage -eq 6 ]; then

  # echo "$0: train nnet3 model"
  # local/nnet3/run_tdnn.sh

#fi

# chain model
if [ $stage -eq 7 ]; then

  # The iVector-extraction and feature-dumping parts coulb be skipped by setting "--train_stage 7"
  echo "$0: train chain model"
  local/chain/run_tdnn.sh

fi

# getting results (see RESULTS file)
if [ $stage -eq 10 ]; then

  echo "$0: extract the results"
  for x in exp/*/decode_test; do [ -d $x ] && grep WER $x/cer_* | utils/best_wer.sh; done 2>/dev/null
  for x in exp/*/*/decode_test; do [ -d $x ] && grep WER $x/cer_* | utils/best_wer.sh; done 2>/dev/null

fi

# finish
echo "$0: all done"

exit 0;
