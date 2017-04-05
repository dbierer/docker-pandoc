#!/bin/bash
WORKDIR=./tmp
OUTPUTDIR=./output
MANUSCRIPTDIR=./manuscript
#
# Setup
#
if [ ! -d "$WORKDIR" ]; then
    mkdir $WORKDIR
fi

if [ -d "$OUTPUTDIR" ]; then
    rm -rf $OUTPUTDIR
fi

mkdir $OUTPUTDIR

if [ -f $WORKDIR/temp.md ]; then
    rm $WORKDIR/temp.md
fi    

touch $WORKDIR/temp.md

#
# Make sure all files have the proper line endings
#
dos2unix book.txt
dos2unix manuscript/*.md

#
# Build the book
#
for FILENAME in $(cat book.txt)
do
    cat manuscript/$FILENAME >> $WORKDIR/temp.md
    echo " " >> $WORKDIR/temp.md
    echo " " >> $WORKDIR/temp.md
    echo " " >> $WORKDIR/temp.md
done


#
# Run the conversions
#
pandoc -o $WORKDIR/cover.html -t html $MANUSCRIPTDIR/title.md
pandoc -o $WORKDIR/body.md -t markdown $WORKDIR/temp.md
pandoc -o $WORKDIR/body.html -t html $WORKDIR/temp.md

#pandoc -o $OUTPUTDIR/final.pdf $WORKDIR/temp.md --toc --epub-cover-image=images/cover.png
#pandoc -o $OUTPUTDIR/final.epub $WORKDIR/temp.md --toc --epub-cover-image=images/cover.png
pandoc -o $WORKDIR/toc.html --template=toc.txt --toc -t html $WORKDIR/body.html

pandoc -o $OUTPUTDIR/final.html -H ./css/style.css --standalone -t html $WORKDIR/cover.html $WORKDIR/toc.html $WORKDIR/body.html
wkhtmltopdf --quiet $OUTPUTDIR/final.html $OUTPUTDIR/final.pdf 

#
# Cleanup
#
rm -rf $WORKDIR