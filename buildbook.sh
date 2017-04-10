#!/bin/bash
WORKDIR=/tmp
OUTPUTDIR=/data/output
MANUSCRIPTDIR=/data/manuscript
TEMPLATESDIR=/data/pandoc 
COPYRIGHTPAGE=""
TOCSWITCH=""
METADATASWITCH=""

#
# Pull in Book Info if it's available.
# Book.info is just a place to set book specific variables like FINALNAMEROOT 
# (File name root) and the current version.
#
if [ -f /data/book.info ]
then
    dos2unix /data/book.info
    source /data/book.info
fi

if [ -e "/data/book.yaml" ]
then
    dos2unix /data/book.yaml
    METADATASWITCH="/data/book.yaml"
fi

#
# Setup
#
if [ -d "$OUTPUTDIR" ]; then
    rm -rf $OUTPUTDIR
fi

mkdir $OUTPUTDIR

if [ ! $? -eq 0 ]
then
    echo " "
    echo "Error:"
    echo "Deleting the output directory."
    echo " "
    exit 1;
fi


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
# If we have a template for the copyright page, generate it. This will 
# substitute the VERSION and DATEPUBLISHED comments for actual data. VERSION 
# is pulled from book.info, date is the date this this script is being run. 
# This is not the copyright date, this is just the date the file was generated.
#
if [ -e "$TEMPLATESDIR/copyright.html" ]
then
    COMMAND1='s/<!--VERSION-->/'$VERSION'/'
    COMMAND2='s,<!--DATEPUBLISHED-->,'$(date +%D)','
    sed -e $COMMAND1 < $TEMPLATESDIR/copyright.html | sed -e $COMMAND2 > $MANUSCRIPTDIR/copyright.md
    COPYRIGHTPAGE="$MANUSCRIPTDIR/copyright.md"
fi

#
# If we have a custom template for the table of contents, set the switch to 
# use it. Otherwise, the default template will be used.
#
if [ -e "$TEMPLATESDIR/toc.html" ]
then
    TOCSWITCH="--template=$TEMPLATESDIR/toc.html"
fi



#
# Run the conversions
#
pandoc -o $WORKDIR/cover.html -t html $MANUSCRIPTDIR/title.md
pandoc -o $WORKDIR/body.html  -t html $WORKDIR/temp.md

pandoc -o $WORKDIR/toc.html $TOCSWITCH --standalone --toc -t html $WORKDIR/body.html
pandoc -o $WORKDIR/$FINALNAMEROOT.html  \
       -H /data/manuscript/css/style.css \
       --standalone \
       -t html \
       $WORKDIR/cover.html $COPYRIGHTPAGE $WORKDIR/toc.html $WORKDIR/body.html
wkhtmltopdf --quiet $WORKDIR/$FINALNAMEROOT.html $WORKDIR/$FINALNAMEROOT.pdf 
wkhtmltoimage --height 768 --width 1024 --quality 100  --encoding UTF-8 $WORKDIR/cover.html $WORKDIR/$FINALNAMEROOT.jpg
#
# My goal was to convert the MD directly into epub. That doesn't seem to work 
# well. So I'm converting from HTML. But I can't get the TOC to generate. 
#
pandoc -S -o $WORKDIR/$FINALNAMEROOT.epub \
       --epub-cover-image=$WORKDIR/$FINALNAMEROOT.jpg \
       $METADATASWITCH $COPYRIGHTPAGE $WORKDIR/temp.md


#
# DO NOT SCREW WITH THIS!
# Docker/Windows 10/pandoc seem to have an issue. If you build the files on 
# the windows share, it will not only fail sometimes, the file that is  
# created is not owned by anyone. So you have to reboot windows before you can 
# delete it. By building it inside the docker container's filesystem, you  
# don't have this problem. pandoc has never failed, but even if it did, the  
# corrupted sfile would be ephemeral.
#
mv $WORKDIR/$FINALNAMEROOT.epub $OUTPUTDIR
mv $WORKDIR/$FINALNAMEROOT.html $OUTPUTDIR
mv $WORKDIR/$FINALNAMEROOT.pdf $OUTPUTDIR
mv $WORKDIR/$FINALNAMEROOT.jpg $OUTPUTDIR

#
# DEBUG ONLY
#
cd $OUTPUTDIR
mkdir work
cd work
cp $OUTPUTDIR/$FINALNAMEROOT.epub .
unzip $FINALNAMEROOT.epub

#
# Cleanup
# This is mainly for when I am working in the docker image itself. It's 
# useless if you are running the Docker container directly on a book.
#
rm -rf $WORKDIR/*  