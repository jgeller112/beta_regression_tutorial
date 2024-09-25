# Beta_Regression_Tutorial

RStudio: [![Binder](http://mybinder.org/badge_logo.svg)](http://mybinder.org/v2/gh/jgeller112/beta_regression_tutorial/main?urlpath=rstudio)

A tutorial paper on beta regression highlighting how to run a beta regression and some of its alternatives with a real-world dataset.

# Renv

This repository has `renv` included in order to allow you to load the same packages that were used to compile the Quarto notebook. To do so, first run this command to check which packages on your machine have different versions:

```
renv::status()
```
and then run this command to load package versions that match what we used:
```
renv::restore(exclude="sf")
```
The `sf` package is excluded because it is difficult to compile `sf` from source, which might happen if a different version of `sf` is loaded. We do not use `sf` in this notebook so any version of this package will do.

# Repository Overview

```{md}
beta_regression_tutorial/
|-- README.md (project directory information)
|-- data
|   |-- miko_data.csv (data file for example in paper)
|-- renv
|   |-- .gitignore
|   |-- activate.R (R packages and versions)
|   |-- settings.json
|-- .Rprofile (activate renv on startup)
|-- .lintr
|-- Beta_Regression-Tutorial.Rproj (project file)
|-- LICENSE
|-- Makefile
|-- beta_regression_draft.qmd (quarto working draft of paper)
|-- bibliography.bib (references for paper)
|-- renv.lock (R package versions for project)
|-- runtime.txt (R version for binder)


```
