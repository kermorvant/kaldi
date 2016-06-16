#!/bin/bash

# Copyright 2016 Teklia - Christopher Kermorvant
# Apache 2.0.

. ./path.sh # Needed for KALDI_ROOT


features_dir=`pwd`/features

for x in train test; do
  mkdir -p exp/make_mfcc/$x
  mkdir -p data/$x
  mkdir -p $features_dir
  python local/extract_features.py local/groundtruth-$x-2011.txt_sorted $features_dir/$x.arkt
  copy-feats ark:$features_dir/$x.arkt ark,scp:$features_dir/$x.ark,data/$x/feats.scp || exit 1;
done

echo "Features preparation succeeded"
