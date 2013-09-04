About
=====

The little CloudStack books

Installation
========

On OSX after installing TexLive you might need the Consolas font.
Grabbed it from [here](http://www.fontpalace.com/font-details/Consolas/) double clicking on the fonts file will install it automatically.

Then a few missing .sty file might need to be installed:

    $ sudo tlmgr update --all
    $ sudo tlmgr install sectsty
    $ sudo tlmgr install paralist
    $ sudo tlmgr install preprint

Then build the pdf files with the Makefile:

    $ make clients-pdf
    $ make installation-pdf

Build the .epub files with:

    $ make clients-epub
    $ make installation-epub

License
=======

The book is licensed under the Apache Software Foundation v2 license

Acknowledgements
================

The format of this book was inspired by the Little Mongodb book by Karl Seguin [@karlseguin] (http://twitter.com/karlseguin)

His book is available on github at <http://github.com/karlseguin/the-little-mongodb-book>.
