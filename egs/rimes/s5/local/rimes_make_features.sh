#!/bin/bash

# Copyright 2016 Teklia - Christopher Kermorvant
# Apache 2.0.

. ./path.sh # Needed for KALDI_ROOT


features_dir=`pwd`/features

for x in train test; do
  mkdir -p exp/make_mfcc/$x
  mkdir -p data/$x
  mkdir -p $features_dir
  python local/extract_features.py local/groundtruth-$x-2011.txt exp/make_mfcc/$x/$x.ark
  copy-feats ark:exp/make_mfcc/$x/$x.ark ark,scp:$features_dir/$x.ark,data/$x/feats.scp
done

echo "Features preparation succeeded"
