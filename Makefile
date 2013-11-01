SOURCE_FILE_NAME_1 = clients-ccc.markdown
BOOK_FILE_NAME_1 = clients

SOURCE_FILE_NAME_2 = installation.markdown
BOOK_FILE_NAME_2 = installation

PDF_BUILDER = pandoc
PDF_BUILDER_FLAGS = \
	--latex-engine xelatex \
	--template ../common/pdf-template.tex \
	--listings

EPUB_BUILDER = pandoc
EPUB_BUILDER_FLAGS = \
	--epub-cover-image

clients-pdf:
	cd en && $(PDF_BUILDER) $(PDF_BUILDER_FLAGS) $(SOURCE_FILE_NAME_1) -o $(BOOK_FILE_NAME_1).pdf

clients-epub: en/title.png en/title.1.txt en/clients.markdown
	$(EPUB_BUILDER) $(EPUB_BUILDER_FLAGS) $^ -o ./en/$(BOOK_FILE_NAME_1).epub

installation-pdf: en/title.png en/title.2.txt en/installation.markdown
	cd en && $(PDF_BUILDER) $(PDF_BUILDER_FLAGS) $(SOURCE_FILE_NAME_2) -o $(BOOK_FILE_NAME_2).pdf

installation-epub: en/title.png en/title.2.txt en/installation.markdown
	$(EPUB_BUILDER) $(EPUB_BUILDER_FLAGS) $^ -o ./en/$(BOOK_FILE_NAME_1).epub

clean:
	rm -f */*.pdf
	rm -f */*.epub
