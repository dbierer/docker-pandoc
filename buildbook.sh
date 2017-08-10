#!/bin/bash
#
# Notify the user we are doing something
#
echo " "
echo "buildBook.sh"
echo "By: Cal Evans <cal@calevans.com>"
echo "License: MIT"
echo "URL: https://blog.calevans.com"
echo "Usage: "
echo "buildbook.sh [rootdir] [workdir]"

#
# Setup
# Here is where to find things
#
ROOTDIR=$1
WORKDIR=$2
OUTPUTDIR=$ROOTDIR/output
MANUSCRIPTDIR=$ROOTDIR/manuscript
TEMPLATESDIR=$ROOTDIR/pandoc 
CONFIGDIR=$ROOTDIR/config


#
# We need these set later on so let's initialize them now. 
#
COPYRIGHTPAGE=""
TOCSWITCH=""
METADATASWITCH=""

#
# BEGIN PROCESSING
#
# If the output directory exists, delete it. If this causes a problem, bail.
#
if [ -d "$OUTPUTDIR" ]; then
    rm -rf $OUTPUTDIR
fi

if [ ! $? -eq 0 ]
then
    echo " "
    echo "Error:"
    echo "Deleting the output directory."
    echo " "
    exit 1
fi

mkdir $OUTPUTDIR



#
# Process book.yaml
# book.yaml is required.
#
if [ -f $ROOTDIR/book.yaml ]
then
    dos2unix -q  $ROOTDIR/book.yaml 
    php -r 'echo yaml_emit(yaml_parse_file("'$ROOTDIR/book.yaml'")["book"]);' > $WORKDIR/book.yaml
    php -r 'foreach (yaml_parse_file("'$ROOTDIR/book.yaml'")["manuscript"] as $key=>$value) {echo $value."\n";}' > $WORKDIR/book.txt   
    php -r 'foreach (yaml_parse_file("'$ROOTDIR/book.yaml'")["variables"] as $key=>$value) {echo $key."=".$value."\n";}' > $WORKDIR/book.sh
    source $WORKDIR/book.sh
    METADATASWITCH="$WORKDIR/book.yaml"
else
    echo " "
    echo "Error:"
    echo "All projects are required to have a $ROOTDIR/book.yaml file."
    echo " "
    exit 2
fi

echo "Filename Root :"$FINALNAMEROOT
echo "Version :" $VERSION
echo " ";

#
# Make sure all files have the proper line endings
#
dos2unix -q  $WORKDIR/book.txt
dos2unix -q  $ROOTDIR/manuscript/*.md


#
# Concatenate the book into on big MarkDown file.
#
for FILENAME in $(cat $WORKDIR/book.txt)
do
    cat $MANUSCRIPTDIR/$FILENAME >> $WORKDIR/$FINALNAMEROOT.md
    echo " " >> $WORKDIR/$FINALNAMEROOT.md
    echo " " >> $WORKDIR/$FINALNAMEROOT.md
    echo " " >> $WORKDIR/$FINALNAMEROOT.md
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
# Make the HTML Cover
pandoc -o $WORKDIR/cover.html -t html $MANUSCRIPTDIR/title.md
if [ ! $? -eq 0 ]
    then
    exit 3
fi


# Convert the MarkDown body file into HTML
pandoc -o $WORKDIR/body.html  -t html $WORKDIR/$FINALNAMEROOT.md
if [ ! $? -eq 0 ]
    then
    exit 4
fi
# Make the Table of Contents for the PDF
pandoc -o $WORKDIR/toc.html $TOCSWITCH --standalone --toc -t html $WORKDIR/body.html
if [ ! $? -eq 0 ]
    then
    exit 5
fi
# Build the standalone HTML that is the basis for the PDF
pandoc -o $WORKDIR/$FINALNAMEROOT.html  \
       -H $ROOTDIR/manuscript/css/style.css \
       --standalone \
       -t html \
       $WORKDIR/cover.html $COPYRIGHTPAGE $WORKDIR/toc.html $WORKDIR/body.html
if [ ! $? -eq 0 ]
    then
    exit 6
fi

# Make the PDF from the HTML
wkhtmltopdf --quiet $WORKDIR/$FINALNAMEROOT.html $WORKDIR/$FINALNAMEROOT.pdf
if [ ! $? -eq 0 ]
    then
    exit 7
fi 
# Make a cover image for the EPUB based on the cover.html we just generated
wkhtmltoimage --quality 100 --encoding UTF-8 $WORKDIR/cover.html $WORKDIR/$FINALNAMEROOT.jpg
if [ ! $? -eq 0 ]
    then
    exit 8
fi

# Make the EPUB
pandoc -S -o $WORKDIR/$FINALNAMEROOT.epub \
       --epub-cover-image=$WORKDIR/$FINALNAMEROOT.jpg \
       --to=epub3 \
       $METADATASWITCH $COPYRIGHTPAGE $WORKDIR/$FINALNAMEROOT.md
if [ ! $? -eq 0 ]
    then
    exit 9
fi

# Make the kindle
kindlegen -verbose -c1 -o $FINALNAMEROOT.mobi $WORKDIR/$FINALNAMEROOT.epub

#
# I don't bail here if kindlegen returns an exit code but it will return an 
# exit code even if it completes successfully but there were issues.
#

# Copy the important stuff to the output dir
#
# DO NOT SCREW WITH THIS!
# Docker/Windows 10/pandoc seem to have an issue. If you build the files on 
# the windows share, it will not only fail sometimes, the file that is  
# created is not owned by anyone. So you have to reboot windows before you can 
# delete it. By building it inside the docker container's filesystem, you  
# don't have this problem. pandoc has never failed, but even if it did, the  
# corrupted files will be ephemeral.
#
cp $WORKDIR/$FINALNAMEROOT.epub $OUTPUTDIR
cp $WORKDIR/$FINALNAMEROOT.html $OUTPUTDIR
cp $WORKDIR/$FINALNAMEROOT.pdf $OUTPUTDIR
cp $WORKDIR/$FINALNAMEROOT.jpg $OUTPUTDIR
cp $WORKDIR/$FINALNAMEROOT.mobi $OUTPUTDIR

#
# Cleanup
# This is mainly for when I am working in the docker image itself. It's 
# useless if you are running the Docker container directly on a book.
# On the other hand, it doesn't hurt anything.
#
#rm -rf $WORKDIR/*  

exit 0
