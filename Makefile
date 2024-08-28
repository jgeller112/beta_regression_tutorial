SOURCE = beta_regression_draft.qmd

all: pdf typst docx

pdf: pdf-man pdf-doc pdf-jou
typst: typst-man typst-doc typst-jou

pdf-man: $(SOURCE)
	quarto render $< --to apaquarto-pdf \
	--output manuscript-$@.pdf \
	-M documentmode:man

pdf-doc: $(SOURCE)
	quarto render $< --to apaquarto-pdf \
	--output manuscript-$@.pdf \
	-M documentmode:doc

pdf-jou: $(SOURCE)
	quarto render $< --to apaquarto-pdf \
	--output manuscript-$@.pdf \
	-M documentmode:jou

docx: $(SOURCE)
	quarto render $< --to apaquarto-docx \
	--output manuscript-$@.docx

typst-man: $(SOURCE)
	quarto render $< --to apaquarto-typst \
	--output manuscript-$@.pdf
	
typst-doc: $(SOURCE)
	quarto render $< --to apaquarto-typst \
	--output manuscript-$@.pdf

typst-jou: $(SOURCE)
	quarto render $< --to apaquarto-typst \
	--output manuscript-$@.pdf
	
clean:
	rm -fr *_files/ *.aux *.log *.out *.tex *.pdf
