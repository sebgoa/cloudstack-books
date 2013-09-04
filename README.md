About
=====

The Little CloudStack Books

Installation
========

For OS X, [BasicTeX](http://www.tug.org/mactex/morepackages.html) is recommended.

Once BasicTeX is installed, the tlmgr and xelatex commands are located at /usr/local/texlive/2013basic/bin/x86_64-darwin/.
Add this to your PATH so the tlmgr and xelatex commands work for the make commands.

You'll also need [PanDoc](https://code.google.com/p/pandoc/downloads/list) installed.

On OS X after installing BasicTeX you might need the Consolas font.
Grabbed it from [here](http://www.fontpalace.com/font-details/Consolas/) double clicking on the fonts file will install it automatically.

Then a few missing .sty files might need to be installed:

    $ sudo tlmgr update --self
    $ sudo tlmgr update --all
    $ sudo tlmgr install sectsty
    $ sudo tlmgr install paralist
    $ sudo tlmgr install preprint

To build the .pdf files:

    $ make clients-pdf
    $ make installation-pdf

To build the .epub files:

    $ make clients-epub
    $ make installation-epub
    
To remove any generated .pdf or .epub files:

    $ make clean
    
All generated files will be in the en directory.

License
=======

The book is licensed under the Apache Software Foundation v2 license

Acknowledgements
================

The format of this book was inspired by The Little MongoDB Book by Karl Seguin [@karlseguin](http://twitter.com/karlseguin)

His book is available on github at <http://github.com/karlseguin/the-little-mongodb-book>.
