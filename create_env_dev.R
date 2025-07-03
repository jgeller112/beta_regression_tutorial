#need this to set path to nix for some reason
# Sys.setenv(PATH = paste("/nix/var/nix/profiles/default/bin", Sys.getenv("PATH"), sep=":"))

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
  "ggrain",
  "tidybayes",
  "webshot2",
  "here",
  "posterior",
  "ggokabeito",
  "patchwork",
  "cowplot",
  "viridis",
  "collapse",
  "transformr",
  "ggrain",
  "glmmTMB"
)

library(rix)

rix(
  date = "2025-04-07",
  r_pkgs = required_packages,
  system_pkgs = c("quarto", "git", "pandoc", "typst", "stanc", "tbb"),
  git_pkgs = list(
    list(
      package_name = "cmdstanr",
      repo_url = "https://github.com/stan-dev/cmdstanr",
      commit = "541f36c74c236a322eaa0908e2e86425790ca2cf"
    ),
    list(
      package_name = "ordbetareg_pack",
      repo_url = "https://github.com/saudiwin/ordbetareg_pack",
      commit = "673292ba8f1b0b0978af8732579f42fc0b37c6ff"
    )
  ),
  tex_pkgs = c(
    "amsmath",
    "ninecolors",
    "apa7",
    "scalerel",
    "threeparttable",
    "threeparttablex",
    "endfloat",
    "environ",
    "multirow",
    "tcolorbox",
    "pdfcol",
    "tikzfill",
    "fontawesome5",
    "framed",
    "newtx",
    "fontaxes",
    "xstring",
    "wrapfig",
    "tabularray",
    "siunitx",
    "fvextra",
    "geometry",
    "setspace",
    "fancyvrb",
    "anyfontsize"
  ),
  shell_hook = "Rscript install_cmdstan.R",
  ide = "code",
  project_path = ".",
  overwrite = TRUE
)
