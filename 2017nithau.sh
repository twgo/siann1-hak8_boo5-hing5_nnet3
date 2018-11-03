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
x=/s5c/data/train_nodev

. ./cmd.sh
. ./utils/parse_options.sh

# configure numbdder of jobs running in parallel, you should adjust these numbers according to your machines

# Now make MFCC plus pitch features.
# mfccdir should be some place with a largish disk where you
# want to store MFCC features.
mfccdir=mfcc

# mfcc
if [ $stage -le -1 ]; then

  echo "$0: making mfccs"
    utils/utt2spk_to_spk2utt.pl $x/utt2spk > $x/spk2utt
    steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj $num_jobs $x exp/make_mfcc/$x $mfccdir || exit 1;
    steps/compute_cmvn_stats.sh $x exp/make_mfcc/$x $mfccdir || exit 1;
    utils/fix_data_dir.sh $x || exit 1;

fi

# data preparat`ion
if [ $stage -eq 2 ]; then
  rm -rf data/lang_2017
  mkdir -p data/tmp
  cp -r  data/local/dict  data/local/dict_2017 
  rm -f data/local/dict_2017/l*
  cat data/local/dict/lexicon.txt /s5c/data/local/dict/lexicon.txt |sort -u> data/local/dict_2017/lexicon.txt
  utils/prepare_lang.sh data/local/dict_2017 "<UNK>"  data/tmp/lang_2017 data/lang_2017

fi
# tri5
if [ $stage -eq 5 ]; then

  # align tri5a
  steps/align_fmllr.sh --cmd "$train_cmd" --nj $num_jobs \
    $x data/lang_2017 exp/tri5a exp/2017_ali || exit 1;


fi


if [ $STAGE -le 16 ]; then
  steps/cleanup/clean_and_segment_data.sh \
    --nj $nj \
    $x data/lang_2017 exp/tri4 exp/tri4_2017_cleanup_log data/2017_cleaned
  mv data/train data/train_guan
  utils/combine_data.sh data/train data/train_guan data/2017_cleaned
  steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" \
    data/train data/lang_2017 exp/tri5a exp/tri5a_ali
fi
