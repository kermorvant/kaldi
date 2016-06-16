#!/bin/bash

# Copyright 2016 Teklia - Christopher Kermorvant
# Apache 2.0.

. ./path.sh # Needed for KALDI_ROOT

tmpdir=`pwd`/data/local/data
mkdir -p $tmpdir


for x in train test; do
  mkdir -p data/$x
  # sort train and test files
  sort local/groundtruth-$x-2011.txt > local/groundtruth-$x-2011.txt_sorted

  # create text transcription files
  cut -d '/' -f 3 < local/groundtruth-$x-2011.txt | sed 's/.tiff//' | sort > data/$x/text


  # now get the "utt2spk" file that says, for each utterance, the speaker name. 
  cut -d '/' -f 3 < local/groundtruth-$x-2011.txt | cut -d ' ' -f1 > $tmpdir/$x-files.txt
  cut -d " " -f 1 data/$x/text | cut -d '_' -f 1 > $tmpdir/$x-id.txt 
  cat $tmpdir/$x-files.txt | sed 's/.tiff//' | paste -d " " - $tmpdir/$x-id.txt  | sort > data/$x/utt2spk
  # create the file that maps from speaker to utterance-list.
  utils/utt2spk_to_spk2utt.pl <data/$x/utt2spk  | sort >data/$x/spk2utt

  utils/validate_data_dir.sh  --no-wav --no-feats data/$x 
done

echo "Data preparation succeeded"
