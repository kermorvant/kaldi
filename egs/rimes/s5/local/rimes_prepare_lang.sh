#!/bin/bash

# Copyright 2012 Johns Hopkins University (Author: Daniel Povey)
# Apache 2.0.

# This script prepares the lang/ directory.
#

. ./path.sh 


# Decided to do this using something like a real lexicon, although we
# could also have used whole-word models.
tmpdir=data/local/dict
lang=data/lang
mkdir -p $tmpdir


# TODO : Create :   lexicon.txt nonsilence_phones.txt  optional_silence.txt  silence_phones.txt extra_questions.txt


cut -d " " -f 2- < data/train/text  > $tmpdir/train.txt
cut -d " " -f 2- < data/test/text  > $tmpdir/test.txt

#cut -d " " -f 2- < data/train/text  | sort | uniq  | grep . > $tmpdir/dic.txt
cat local/test_dictionary_task_wr3_icdar_2011.txt > $tmpdir/dic.txt
echo "<UNK> SPN" > $tmpdir/lexicon.txt
cat $tmpdir/dic.txt | sed 's/\(.\)/\1 /g' | paste $tmpdir/dic.txt - >> $tmpdir/lexicon.txt


# and note, we'll have a silence phone, but it won't appear
# in this form of lexicon as there's no silence word; it's an option
# in the lexicon FST that gets added by the script.

mkdir -p $lang/phones

# symbol-table for words:
cat $tmpdir/lexicon.txt | awk '{print $1}' | awk 'BEGIN {print "<eps> 0"; n=1;} { printf("%s %s\n", $1, n++); }' \
  >$lang/words.txt

#echo $lang/words.txt
#head $lang/words.txt
# list of phones.
cat $tmpdir/lexicon.txt | awk '{for(n=2;n<=NF;n++) seen[$n]=1; } END{print "sil"; for (w in seen) { print w; }}' \
 >$tmpdir/phone.list

#echo $tmpdir/phone.list
#head $tmpdir/phone.list

# symbol-table for phones:
cat $tmpdir/phone.list | awk 'BEGIN {print "<eps> 0"; n=1;} { printf("%s %s\n", $1, n++); }' \
  >$lang/phones.txt

cat $tmpdir/phone.list > $tmpdir/nonsilence_phones.txt  
echo 'SIL' > $tmpdir/silence_phones.txt 
touch $tmpdir/extra_questions.txt
echo 'SIL' > $tmpdir/optional_silence.txt



# Now we prepare a simple grammar G.fst that's a kind of loop of
# digits (no silence in this, since that's handled in L.fst)

lm_suffix=o1g

$SRILM/ngram-count -text $tmpdir/test.txt  -no-sos -no-eos -order 1  -lm $tmpdir/lm_${lm_suffix}.arpa -wbdiscount  -limit-vocab -vocab $tmpdir/dic.txt  -unk -map-unk "<UNK>" 

$SRILM/ngram -lm $tmpdir/lm_${lm_suffix}.arpa -ppl $tmpdir/test.txt  # consider -debug 2


cat $tmpdir/lm_${lm_suffix}.arpa | \
    grep -v '<s> <s>' | \
    grep -v '</s> <s>' | \
    grep -v '</s> </s>' | \
    arpa2fst - | fstprint | awk '/^0/{print "0\t1\t"$3"\t"$4"\t"$5}END{print "1"}' |\
    utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$lang/words.txt \
      --osymbols=$lang/words.txt  --keep_isymbols=false --keep_osymbols=false | \
     fstrmepsilon | fstarcsort --sort_type=ilabel > $lang/G.fst
 fstisstochastic $lang/G.fst



# G with real LM
#cat $tmpdir/lm_${lm_suffix}.arpa | \
#    grep -v '<s> <s>' | \
#    grep -v '</s> <s>' | \
#    grep -v '</s> </s>' | \
#    arpa2fst - | fstprint | \
#    utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$lang/words.txt \
#      --osymbols=$lang/words.txt  --keep_isymbols=false --keep_osymbols=false | \
#     fstrmepsilon | fstarcsort --sort_type=ilabel > $lang/G.fst
#fstisstochastic $lang/G.fst


./utils/prepare_lang.sh data/local/dict/ '<UNK>' data/local/lang data/lang

exit 0;



