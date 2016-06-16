#!/bin/bash


. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

# This is a shell script, but it's recommended that you run the commands one by
# one by copying and pasting into the shell.

rimes=/data/rimes

# The following command prepares the data/{train,dev,test} directories.
local/rimes_data_prep.sh || exit 1;
local/rimes_prepare_lang.sh  || exit 1;
utils/validate_lang.pl data/lang/ # Note; this actually does report errors,
   # and exits with status 1, but we've checked them and seen that they
   # don't matter (this setup doesn't have any disambiguation symbols,
   # and the script doesn't like that).

# Now make MFCC features.
# mfccdir should be some place with a largish disk where you
# want to store MFCC features.

mfccdir=mfcc
local/rimes_make_features.sh || exit 1;
for x in  test train; do
  steps/compute_cmvn_stats.sh --fake data/$x exp/make_mfcc/$x $mfccdir || exit 1;
done

utils/subset_data_dir.sh data/train 11265 data/train_10k



# try --boost-silence 1.25 to some of the scripts below (also 1.5, if that helps...
# effect may not be clear till we test triphone system.  See
# wsj setup for examples (../../wsj/s5/run.sh)

#echo "--delta-order=0" > exp/mono0a/delta_opts
local/train_mono.sh  --nj 4 --cmd "$train_cmd" data/train_10k data/lang exp/mono0a

echo "--delta-order=0" > exp/mono0a/delta_opts
utils/mkgraph.sh --mono data/lang exp/mono0a exp/mono0a/graph 
  for i in 1 11 21 31 final
    do 

    steps/decode.sh --nj 10 --cmd "$decode_cmd" \
      --scoring-opts "--min-lmwt 50 --max-lmwt 50" --model exp/mono0a/$i.mdl \
          exp/mono0a/graph data/test exp/mono0a/decode
    grep WER exp/mono0a/decode/wer*
  done
exit 1;

steps/align_si.sh --nj 4 --cmd "$train_cmd" \
   data/train data/lang exp/mono0a exp/mono0a_ali

steps/train_deltas.sh --cmd "$train_cmd" \
    300 3000 data/train data/lang exp/mono0a_ali exp/tri1


 utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph
 steps/decode.sh --nj 10 --cmd "$decode_cmd" \
      exp/tri1/graph data/test exp/tri1/decode

steps/align_si.sh --nj 10 --cmd "$train_cmd" \
  data/train data/lang exp/tri1 exp/tri1_ali || exit 1;


steps/train_lda_mllt.sh --cmd "$train_cmd" --mllt-iters '' \
--splice-opts "--left-context=3 --right-context=3" \
2500 15000 data/train data/lang exp/tri1_ali exp/tri2b 

 utils/mkgraph.sh data/lang exp/tri2b exp/tri2b/graph
 steps/decode.sh --nj 10 --cmd "$decode_cmd" \
      exp/tri2b/graph data/test exp/tri2b/decode

# Example of looking at the output.
# utils/int2sym.pl -f 2- data/lang/words.txt  exp/tri1/decode/scoring/19.tra | sed "s/ $//" | sort | diff - data/test/text


# Getting results [see RESULTS file]
# for x in exp/*/decode*; do [ -d $x ] && grep SER $x/wer_* | utils/best_wer.sh; done

#exp/mono0a/decode/wer_17:%SER 3.67 [ 319 / 8700 ]
#exp/tri1/decode/wer_19:%SER 2.64 [ 230 / 8700 ]
