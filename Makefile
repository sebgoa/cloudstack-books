SOURCE_FILE_NAME = cloudstack.markdown
BOOK_FILE_NAME = cloudstack

PDF_BUILDER = pandoc
PDF_BUILDER_FLAGS = \
	--latex-engine xelatex \
	--template ../common/pdf-template.tex \
	--listings

EPUB_BUILDER = pandoc
EPUB_BUILDER_FLAGS = \
	--epub-cover-image


en/cloudstack.pdf:
	cd en && $(PDF_BUILDER) $(PDF_BUILDER_FLAGS) $(SOURCE_FILE_NAME) -o $(BOOK_FILE_NAME).pdf

en/cloudstack.epub: en/title.png en/title.txt en/cloudstack.markdown
	$(EPUB_BUILDER) $(EPUB_BUILDER_FLAGS) $^ -o $@

clean:
	rm -f */$(BOOK_FILE_NAME).pdf
	rm -f */$(BOOK_FILE_NAME).epub
