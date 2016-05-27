#!/bin/bash

# Copyright 2016 Teklia - Christopher Kermorvant
# Apache 2.0.

. ./path.sh # Needed for KALDI_ROOT


features_dir=`pwd`/features

for x in train test; do
  mkdir -p exp/make_mfcc/$x
  mkdir -p data/$x
  mkdir -p $features_dir
  #cut -d ' ' -f 1 local/groundtruth_$x2011.txt  | sed 's/lot/\/home\/kermorvant\/Data\/Images\/Latin\/French\/Rimes\/imagettes_mots_cursif_rescaled\/lot/;s/.tiff/.png/' | sort > $x_files_fullpath.txt

  #time prepocressor -inputFile $x_files_fullpath.txt -pipeline "grayscale | flip | convertToFloat | normalize -newMax 1 | featExtract -winWidth 3 -winShift 2 -featRawCellHeight 1 -featRawCellWidth 1 -featRawCellShift 1 -kaldiFile $x.ark,f | devNull"
  python local/extract_features.py local/groundtruth-$x-2011.txt exp/make_mfcc/$x/$x.ark
  copy-feats ark:exp/make_mfcc/$x/$x.ark ark,scp:$features_dir/$x.ark,data/$x/feats.scp

  #rm exp/make_mfcc/$x/$x.ark
  #sed 's/'$x'/\/Users\/christo\/Tools\/kaldi-trunk\/egs\/rimes\/s5\/features\/'$x'/g' < data/$x/$x.scp > data/$x/feats.scp

done

echo "Features preparation succeeded"
