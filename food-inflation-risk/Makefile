.PHONY: figures manuscript protocol all clean

figures:
	Rscript code/R/make_figures.R

manuscript: figures
	cd manuscript && latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex

protocol:
	cd protocol && latexmk -pdf -interaction=nonstopmode -halt-on-error protocol.tex

all: manuscript protocol

clean:
	cd manuscript && latexmk -C
	cd protocol && latexmk -C
