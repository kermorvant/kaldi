imgpath=/Users/christo/Data/Images/Latin/French/Rimes/imagettes_mots_cursif
testfiles=local/groundtruth-test-2011.txt
decode_dir=/Users/christo/Tools/kaldi-kermorvant/egs/rimes/s5/exp/mono0a/decode
lattice-to-fst "ark:gunzip -c "$decode_dir"/lat.1.gz|" ark,t:$decode_dir/1.fsts
utils/int2sym.pl -f 3 data/lang/words.txt $decode_dir/1.fsts > $decode_dir/1.txt.fsts

detail_dir=$decode_dir/details/
mkdir -p $detail_dir

awk -v RS="" -v detail_dir=$detail_dir '{output=detail_dir"/"$1".txt";print $0 > (output); close(output)}' $decode_dir/1.txt.fsts

echo "<html><body>" > $detail_dir/index.html
cat $testfiles | while read line; do
#for i in `ls $detail_dir/*.txt`; do
	fullimg=`echo $line | cut -d " " -f 1`
	annot=`echo $line | cut -d " " -f 2`
	img=`basename $fullimg`
	img="${img%.*}"
    echo $fullimg $annot $img
    cat $detail_dir/$img.txt | tail -n +2 | fstcompile --isymbols=data/lang/words.txt --keep_isymbols| fstproject | fstminimize|  fstdraw --portrait --acceptor | dot -Tsvg > $detail_dir/$img".svg"
    linkname=$detail_dir/$img".svg"
    echo '<h2>'$img' : '$annot'</h2><img src="'$imgpath/$fullimg'" ><img src="'$linkname'" ></br>' >>$detail_dir/index.html
done;
echo "</body></html>" >> $detail_dir/index.html


