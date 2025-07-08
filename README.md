
[![DOI](https://zenodo.org/badge/826370441.svg)](https://doi.org/10.5281/zenodo.15830595)


This repository contains  materials and code for our manuscript "A Beta Way: A Tutorial For Using Beta Regression in Psychological Research to Analyze Proportional and Percentage Data" 

## Authors/Contributors 
- Jason Geller* (drjasongeller@gmail.com)
- Robert Kubinec
- Chelsea M. Parlett Pelleriti
- Matti Vuorre

```
beta_regression_tutorial/
├── .github/
│   └── workflows/
│       └── <workflow-files>.yml     # GitHub Actions workflows
├── .vscode/
│   └── settings.json                # Editor config (air formatter)
├── manuscript/
│   ├── data/
│   │   ├── fluency_data.csv
│   │   └── miko_data.csv
│   ├── Figures/
│   │   └── <rendered_figures>.png
│   ├── _extensions/
│   │   └── apaquarto/
│   ├── ms.qmd                       # Main manuscript file
│   └── bibliography.bib            # Paper references
├── .Rprofile                      
├── .gitignore                      # Ignore .DS_Store, etc.
├── LICENSE                         # Project license
├── README.md                       # Project overview
├── air.toml                        # Air formatter config
├── create_env_dev.R               # Script for dev environment with rix
├── default.nix                    # Nix definition for full reproducibility
├── grateful-refs.bib              # Generated bib for installed packages
├── grateful-report.html           # Report of installed packages
├── install_cmdstan.R              # Install latest CmdStan in shell
├── nix-beta_reg_ms.Rproj          # RStudio project file
```

## Overview

- **`.github`**: contains render_paper.yml that builds the manuscript using nix anew every time it detects a new change
- **`.Rprofile`**: Configuration file for R sessions.
- **`.gitignore`**: Specifies files and directories for Git to ignore.
- **`Rproj`**: RStudio project file.
- **`README.md`**: Provides an overview of the project.
- **`create_env_dev.R`**: Script to set up the nix environment
- **`default.nix`**: Configuration file for the Nix package manager.
- **`.project`**: Project configuration file.

## Directories

- **`_extensions/`**: Contains extensions, including:
  - **`wjschne/apaquarto/`**

- **`manuscript/`**: Manuscript-related files.


## Data

- All data for this manuscript can be found under /data.
 
# Reproducing the Manuscript

This repository contains all the resources needed to reproduce the manuscript associated with this project. To ensure maximum reproducibility, we used [Quarto](https://quarto.org/) for creating the manuscript. This allows computational figures, tables, and text to be programmatically included directly in the manuscript, ensuring that all results are seamlessly integrated into the document. We also provide a file called default.nix which contains the definition of the development environment that was used to work on the analysis. Reproducers can easily re-use the exact same environment by installing the Nix package manager and using the included default.nix file to set up the right environment.

## Video Tutorial

Here is a video tutorial showing an example of how to reproduce a manuscript using Nix/Rix

[![Reproduce Manuscript with Nix/Rix](https://img.youtube.com/vi/nb9NfGfwAwc/0.jpg)](https://www.youtube.com/watch?v=nb9NfGfwAwc)

## Prerequisites

### Required Software
To reproduce the manuscript, you will need the following if not using rix/nix:

1. **Git** - To get Github repos [https://git-scm.com/downloads]
2. **RStudio** or **Positron**  or **VS Code**- To run the R scripts and render the Quarto document.
3. **Quarto** - To compile the manuscript.
4. **apaQuarto** - APA manuscript template [https://github.com/wjschne/apaquarto/tree/main] (you should not have to download this if you download the repo as the _extension file contains all the files needed)

## Steps to Reproduce

### Nix/Rix

#### Installation Guides

- **Nix and Rix**
  - For Windows and Linux: [Setup Guide](https://docs.ropensci.org/rix/articles/b1-setting-up-and-using-rix-on-linux-and-windows.html)
  - For macOS: [Setup Guide](https://docs.ropensci.org/rix/articles/b2-setting-up-and-using-rix-on-macos.html)

#### 1. Clone the Repository

Clone this repository to your local machine:

```bash
git clone https://github.com/jgeller112/beta_regression_tutorial.git
cd nix_beta_regression_ms
```
- You can also clone the repository from Github using the SSH and opeining a project in RStudio/Positron. 
  
<img width="2083" alt="Screenshot 2025-03-18 at 1 57 14 PM" src="https://github.com/user-attachments/assets/003c7cfa-393b-408d-8aa6-99bb25f0adfe" />
 
#### 2. Open the Project
Open the R project file `nix-beta_regression_ms.Rproj` in RStudio or Positron.

#### 3. Build the Environment
Use Nix to set up the reproducible environment:
```
nix-build
```

```
nix-shell
```
Once in the shell, You can: 

1. Reproduce the manuscript

```
quarto render "~/manuscript/ms.qmd"
```


or 

2. Launch your IDE in the correct environment in run code and analyses:

- Positron
  - To use Positron from the shell you will need to make sure the correct path is set (see https://github.com/posit-dev/positron/discussions/4485#discussioncomment-10456159). Once this is done you can open Positron from the shell
  - If you are using Positron within WSL/Windows you need to download WSL for positron and direnv in Positron.
```bash
positron
```
For RStudio (linux only), simply type:
```bash
rstudio
```



###  Run locally with packages installed systemwide

Finally, it’s also possible to forget {rix} and instead run everything using R packages that you install systemwide.

- Make sure the required software is installed above and you have the following packages:

  - R 4.4.1 (or later) and RStudio.

  - Quarto 1.6.1 (or later)
  
  - A C++ compiler and GNU Make. Complete instructions for macOS, Windows, and Linux are available at CmdStan’s documentation. In short, do this:

    - macOS: Run this terminal command and follow the dialog that pops up after to install macOS’s Command Line Tools:

```
  xcode-select --install
```

Windows: Download and install Rtools from CRAN

Linux: Run this terminal command (depending on your distribution; this assumes Ubuntu/Debian):

```
sudo apt install g++ make
(macOS only): Download and install XQuartz
```

## Packages Used
| Package        | Version     | Citation                                                                                      |
|----------------|-------------|-----------------------------------------------------------------------------------------------|
| base           | 4.5.1       | R Core Team (2025)                                                                            |
| bayesplot      | 1.13.0      | Gabry et al. (2019); Gabry and Mahr (2025)                                                    |
| brms           | 2.22.0      | Bürkner (2017); Bürkner (2018); Bürkner (2021)                                                |
| cmdstanr       | 0.9.0.9000  | Gabry et al. (2025)                                                                           |
| cowplot        | 1.1.3       | Wilke (2024)                                                                                  |
| easystats      | 0.7.4       | Lüdecke et al. (2022)                                                                         |
| extraDistr     | 1.10.0      | Wolodzko (2023)                                                                               |
| geomtextpath   | 0.1.5       | Cameron and van den Brand (2025)                                                              |
| ggdist         | 3.3.3       | Kay (2024); Kay (2025)                                                                        |
| ggokabeito     | 0.1.0       | Barrett (2021)                                                                                |
| glmmTMB        | 1.1.8       | Brooks et al. (2017); Magnusson et al. (2022)                                                 |
| ggrain         | 0.1.0       | Author (Unpublished package or GitHub repository)                                             |
| here           | 1.0.1       | Müller (2020)                                                                                 |
| knitr          | 1.50        | Xie (2014); Xie (2015); Xie (2025)                                                            |
| marginaleffects| 0.27.0      | Arel-Bundock, Greifer, and Heiss (2024)                                                       |
| ordbetareg     | 0.8         | Kubinec (2025)                                                                                |
| patchwork      | 1.3.1       | Pedersen (2025)                                                                               |
| performance    | 0.14.0      | Lüdecke et al. (2021)                                                                         |
| posterior      | 1.6.1       | Vehtari et al. (2021); Lambert and Vehtari (2022); Margossian et al. (2024); Vehtari et al. (2024); Bürkner et al. (2025) |
| quarto         | 1.4.553     | Allaire et al. (2024)                                                                         |
| rix            | 0.16.0      | Rodrigues and Baumann (2025)                                                                  |
| rmarkdown      | 2.29        | Xie, Allaire, and Grolemund (2018); Xie, Dervieux, and Riederer (2020); Allaire et al. (2024) |
| scales         | 1.4.0       | Wickham, Pedersen, and Seidel (2025)                                                          |
| tidybayes      | 3.0.5       | Kay (2024); Kay (2025)                                                                        |
| tidyverse      | 2.0.0       | Wickham et al. (2019)                                                                         |
| tinytable      | 0.9.0       | Arel-Bundock (2025)                                                                           |
| transformr     | 0.1.4       | Pedersen (2022)                                                                               |
| webshot2       | 0.1.0       | Cheng, Xie (2022)                                                                             |


```
required_packages = c(
  "tidyverse",
  "brms",
  "geomtextpath",
  "quarto",
  "tinytable",
  "marginaleffects",
  "extraDistr",
  "easystats",
  "scales",
  "tidybayes",
  "webshot2",
  "here",
  "posterior",
  "ggokabeito",
  "patchwork",
  "cowplot",
  "collapse",
  "transformr",
  "ggrain",
  "glmmTMB"
)
```

```
install.packages("cmdstanr", repos = c("https://stan-dev.r-universe.dev", "https://packagemanager.posit.co/cran/latest"))
```

```
# install cmdstan 
cmdstanr::install_cmdstan()
```

1. Download the repository from Github

<img width="2083" alt="Screenshot 2025-03-18 at 1 57 14 PM" src="https://github.com/user-attachments/assets/003c7cfa-393b-408d-8aa6-99bb25f0adfe" />


2.  Open `beta_regression_tutorial.Rproj` to open a new RStudio project.

3.  Open `/manuscript/ms.qmd`

4.  Run each chunk in the manuscript

*Note that some computations can take a long time, depending on computer performance etc*
