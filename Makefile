SOURCE = index.qmd

all: renv html

renv: renv.lock
	Rscript -e "renv::restore()"

html: $(SOURCE)
	quarto render

clean:
	rm -fr *_cache/ *_files/ *.aux *.log *.out *.tex *.pdf

.PHONY: all clean
