SOURCE = beta_regression_draft.qmd

all: pdf typst docx

pdf: pdf-man pdf-doc pdf-jou

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

typst: $(SOURCE)
	quarto render $< --to typst \
	--output manuscript-$@.pdf

clean:
	rm -fr *_files/ *.aux *.log *.out *.tex *.pdf
