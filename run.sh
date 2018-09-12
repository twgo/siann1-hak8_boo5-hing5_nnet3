#!/bin/bash
#
# Copyright 2018, Yuan-Fu Liao, National Taipei University of Technology, yfliao@mail.ntut.edu.tw
#
# Before you run this recips, please apply, download and put or make a link of the corpus under this folder (folder name: "NER-Trs-Vol1").
# For more detail, please check:
# 1. Formosa Speech in the Wild (FSW) project (https://sites.google.com/speech.ntut.edu.tw/fsw/home/corpus)
# 2. Formosa Speech Recognition Challenge (FSW) 2018 (https://sites.google.com/speech.ntut.edu.tw/fsw/home/challenge)
stage=-2
num_jobs=20

# shell options
set -e -o pipefail

. ./cmd.sh
. ./utils/parse_options.sh

# configure number of jobs running in parallel, you should adjust these numbers according to your machines
# data preparation
if [ $stage -le -2 ]; then
  utils/utt2spk_to_spk2utt.pl data/train/utt2spk > data/train/spk2utt
  rm -rf data/lang_train
  mkdir -p data/tmp
  utils/prepare_lang.sh data/local/dict "<UNK>"  data/tmp/lang_train data/lang_train


fi

# Now make MFCC plus pitch features.
# mfccdir should be some place with a largish disk where you
# want to store MFCC features.
mfccdir=mfcc

# mfcc
if [ $stage -le -1 ]; then

  echo "$0: making mfccs"
  for x in train; do
    steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj $num_jobs data/$x exp/make_mfcc/$x $mfccdir || exit 1;
    steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir || exit 1;
    utils/fix_data_dir.sh data/$x || exit 1;
  done

fi

# mono
if [ $stage -le 0 ]; then

  echo "$0: train mono model"
  # Make some small data subsets for early system-build stages.
  echo "$0: make training subsets"
  utils/subset_data_dir.sh --shortest data/train 3000 data/train_mono

  # train mono
  steps/train_mono.sh --boost-silence 1.25 --cmd "$train_cmd" --nj $num_jobs \
    data/train_mono data/lang exp/mono || exit 1;

  # Get alignments from monophone system.
  steps/align_si.sh --boost-silence 1.25 --cmd "$train_cmd" --nj $num_jobs \
    data/train data/lang exp/mono exp/mono_ali || exit 1;


fi

# tri1
if [ $stage -le 1 ]; then

  echo "$0: train tri1 model"
  # train tri1 [first triphone pass]
  steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
   2500 20000 data/train data/lang exp/mono_ali exp/tri1 || exit 1;

  # align tri1
  steps/align_si.sh --cmd "$train_cmd" --nj $num_jobs \
    data/train data/lang exp/tri1 exp/tri1_ali || exit 1;


fi

# tri2
if [ $stage -le 2 ]; then

  echo "$0: train tri2 model"
  # train tri2 [delta+delta-deltas]
  steps/train_deltas.sh --cmd "$train_cmd" \
   2500 20000 data/train data/lang exp/tri1_ali exp/tri2 || exit 1;

  # align tri2b
  steps/align_si.sh --cmd "$train_cmd" --nj $num_jobs \
    data/train data/lang exp/tri2 exp/tri2_ali || exit 1;


fi

# tri3a
if [ $stage -le 3 ]; then

  echo "$-: train tri3 model"
  # Train tri3a, which is LDA+MLLT,
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
   2500 20000 data/train data/lang exp/tri2_ali exp/tri3a || exit 1;


fi

# tri4
if [ $stage -le 4 ]; then

  echo "$0: train tri4 model"
  # From now, we start building a more serious system (with SAT), and we'll
  # do the alignment with fMLLR.
  steps/align_fmllr.sh --cmd "$train_cmd" --nj $num_jobs \
    data/train data/lang exp/tri3a exp/tri3a_ali || exit 1;

  steps/train_sat.sh --cmd "$train_cmd" \
    2500 20000 data/train data/lang exp/tri3a_ali exp/tri4a || exit 1;

  # align tri4a
  steps/align_fmllr.sh  --cmd "$train_cmd" --nj $num_jobs \
    data/train data/lang exp/tri4a exp/tri4a_ali


fi

# tri5
if [ $stage -le 5 ]; then

  echo "$0: train tri5 model"
  # Building a larger SAT system.
  steps/train_sat.sh --cmd "$train_cmd" \
    3500 100000 data/train data/lang exp/tri4a_ali exp/tri5a || exit 1;

  # align tri5a
  steps/align_fmllr.sh --cmd "$train_cmd" --nj $num_jobs \
    data/train data/lang exp/tri5a exp/tri5a_ali || exit 1;


fi

exit 0

# chain model
if [ $stage -le 7 ]; then

  # The iVector-extraction and feature-dumping parts coulb be skipped by setting "--train_stage 7"
  echo "$0: train chain model"
  local/chain/run_tdnn.sh

fi

# getting results (see RESULTS file)
if [ $stage -le 10 ]; then

  echo "$0: extract the results"
  for x in exp/*/decode_test; do [ -d $x ] && grep WER $x/cer_* | utils/best_wer.sh; done 2>/dev/null
  for x in exp/*/*/decode_test; do [ -d $x ] && grep WER $x/cer_* | utils/best_wer.sh; done 2>/dev/null

fi

# finish
echo "$0: all done"

exit 0;
