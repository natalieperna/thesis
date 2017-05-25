filename=MScThesis
lagda_dir=Figures/Agda

all:	figs
	pdflatex ${filename}
	bibtex ${filename}||true
	pdflatex ${filename}
	bibtex ${filename}||true
	pdflatex ${filename}

quick:
	pdflatex ${filename}

figs:
	cd ${lagda_dir}; \
	find . -name '*.lagda' -exec agda --latex {} \;

read:
	evince ${filename}.pdf &

clean:
	rm -rf ${lagda_dir}/latex/
	rm -f ${filename}.{pdf,log,aux,out,bbl,blg,idx,lof,lot,ptb,toc}
