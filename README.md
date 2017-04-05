# Pandoc Docker container with XeLaTeX

## This fork is mantained by Cal Evans <cal@calevans.com>

This project will take a specifically formatted book project and create :

- HTML
- PDF
- EPUB
- MOBI (Kindle)

# Requrements
For this project to work, several requirements  must be met.

## Directories
The following directories are required to be present in the root directory.

- manuscript
- images
- final
- css *

* Optional. If present, it will be used, otherwise, the process will continue without it. 

## Files
The following files are required for the system to operate.

- `manuscript/book.txt`
A list of the chapter files in the order they are to be presented

- `manuscript/book.info`
All the info about the book that is necessary to create the various files but cannot be derived from the other files.

- `images/cover.[png|jpg]`
If it exists, this is the cover of the ebook. Otherwise, no cover will be processed.

# Process
When the container is properly executed, it will run `./buildbook.sh`. This is the starting point. `./builbook.sh` will check to make sure that all necessary files are present. It will then generate the output in all three formats. 


## Linux/macOS
```
$ docker run --rm -v `pwd`:/data pandoc
```

## Windows
```
docker run --rm -v %cd%:/data pandoc
```