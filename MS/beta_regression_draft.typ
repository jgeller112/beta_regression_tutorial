// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}

//#assert(sys.version.at(1) >= 11 or sys.version.at(0) > 0, message: "This template requires Typst Version 0.11.0 or higher. The version of Quarto you are using uses Typst version is " + str(sys.version.at(0)) + "." + str(sys.version.at(1)) + "." + str(sys.version.at(2)) + ". You will need to upgrade to Quarto 1.5 or higher to use apaquarto-typst.")

// counts how many appendixes there are
#let appendixcounter = counter("appendix")
// make latex logo
// https://github.com/typst/typst/discussions/1732#discussioncomment-6566999
#let TeX = style(styles => {
  set text(font: ("New Computer Modern", "Times", "Times New Roman"))
  let e = measure("E", styles)
  let T = "T"
  let E = text(1em, baseline: e.height * 0.31, "E")
  let X = "X"
  box(T + h(-0.15em) + E + h(-0.125em) + X)
})
#let LaTeX = style(styles => {
  set text(font: ("New Computer Modern", "Times", "Times New Roman"))
  let a-size = 0.66em
  let l = measure("L", styles)
  let a = measure(text(a-size, "A"), styles)
  let L = "L"
  let A = box(scale(x: 105%, text(a-size, baseline: a.height - l.height, "A")))
  box(L + h(-a.width * 0.67) + A + h(-a.width * 0.25) + TeX)
})

#let firstlineindent=0.5in

// documentmode: man
#let man(
  title: none,
  runninghead: none,
  margin: (x: 1in, y: 1in),
  paper: "us-letter",
  font: ("Times", "Times New Roman"),
  fontsize: 12pt,
  leading: 18pt,
  spacing: 18pt,
  firstlineindent: 0.5in,
  toc: false,
  lang: "en",
  cols: 1,
  doc,
) = {

  set page(
    paper: paper,
    margin: margin,
    header-ascent: 50%,
    header: grid(
      columns: (9fr, 1fr),
      align(left)[#upper[#runninghead]],
      align(right)[#counter(page).display()]
    )
  )


 
if sys.version.at(1) >= 11 or sys.version.at(0) > 0 {
  set table(    
    stroke: (x, y) => (
        top: if y <= 1 { 0.5pt } else { 0pt },
        bottom: .5pt,
      )
  )
}
  set par(
    justify: false, 
    leading: leading,
    first-line-indent: firstlineindent
  )

  // Also "leading" space between paragraphs
  set block(spacing: spacing, above: spacing, below: spacing)

  set text(
    font: font,
    size: fontsize,
    lang: lang
  )

  show link: set text(blue)

  show quote: set pad(x: 0.5in)
  show quote: set par(leading: leading)
  show quote: set block(spacing: spacing, above: spacing, below: spacing)
  // show LaTeX
  show "TeX": TeX
  show "LaTeX": LaTeX

  // format figure captions
  show figure.where(kind: "quarto-float-fig"): it => [
    #if int(appendixcounter.display().at(0)) > 0 [
      #heading(level: 2)[#it.supplement #appendixcounter.display("A")#it.counter.display()]
    ] else [
      #heading(level: 2)[#it.supplement #it.counter.display()]
    ]
    #par[#emph[#it.caption.body]]
    #align(center)[#it.body]
  ]
  
  // format table captions
  show figure.where(kind: "quarto-float-tbl"): it => [
    #if int(appendixcounter.display().at(0)) > 0 [
      #heading(level: 2)[#it.supplement #appendixcounter.display("A")#it.counter.display()]
    ] else [
      #heading(level: 2)[#it.supplement #it.counter.display()]
    ]
    #par[#emph[#it.caption.body]]
    #block[#it.body]
  ]

 // Redefine headings up to level 5 
  show heading.where(
    level: 1
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(center)
    #set text(size: fontsize)
    #it.body
  ]
  
  show heading.where(
    level: 2
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(left)
    #set text(size: fontsize)
    #it.body
  ]
  
  show heading.where(
    level: 3
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(left)
    #set text(size: fontsize, style: "italic")
    #it.body
  ]

  show heading.where(
    level: 4
  ): it => text(
    size: 1em,
    weight: "bold",
    it.body
  )

  show heading.where(
    level: 5
  ): it => text(
    size: 1em,
    weight: "bold",
    style: "italic",
    it.body
  )

  if cols == 1 {
    doc
  } else {
    columns(cols, gutter: 4%, doc)
  }


}
#show: document => man(
  runninghead: "BETA REGRESSION TUTORIAL",
  lang: "en",
  document,
)
#import "@preview/fontawesome:0.1.0": *


\
\
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
A Beta Way: A Tutorial For Using Beta Regression In Pychological Research To Analyze Proportional and Percentage Data
]
)
]
#set align(center)
#block[
\
Jason Geller#super[1];, Robert Kubinec#super[2];, and Matti Vuorre#super[3]

#super[1];Department of Psychology and Neuroscience, Boston College

#super[2];NYU Abu Dhabi

#super[3];Tilburg University

]
#set align(left)
\
\
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Author Note
]
)
]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Jason Geller #box(image("_extensions/wjschne/apaquarto/ORCID-iD_icon-vector.svg", width: 4.23mm)) http:\/\/orcid.org/0000-0002-7459-4505

Correspondence concerning this article should be addressed to Jason Geller, Department of Psychology and Neuroscience, Boston College, McGuinn 300, Chestnut Hill, MA 1335, USA, Email: drjasongeller\@gmail.com

#pagebreak()

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Abstract
]
)
]
#block[
Rates, percentages, and proportional data are widespread in psychology. These data are usually analyzed with methods falling under the general linear model, which are not ideal for this type of data. A better alterantive is the beta regession model which is based on the beta distribution. A beta regression can be used to model data that is non-normal, heteroscedastic, and bounded between an interval \[0,1\]. Thus, the beta regression model is well-suited to examine outcomes in psycholgical research expressed as proportions, percentages, or ratios. The overall purpose of this tutorial is to give researchers a hands-on demonstration of how to use beta regression using a real example from the psychological literature. First, we introduce the beta distribution and the beta regression model highlighting crucial components and assumptions. Second, we highlight how to conduct a beta regression in R using an example dataset from the learning and memory literature. Some extensions of the beta model are then discussed (e.g., zero-inflated, zero- one-inflated, and ordered beta). We present accompanying R code throughout. All code to reproduce this paper can be found on Github:

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
#emph[Keywords];: Beta regression, tutorial, psychology, learning and memory

#pagebreak()

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
A Beta Way: A Tutorial For Using Beta Regression In Pychological Research To Analyze Proportional and Percentage Data
]
)
]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
In psychological research, it is common to use response outcomes that are percentages or proportions. For instance, in educational and cognitive research, one popular way to assess metamemory is with judgments of learning (JOLS) which involve participants providing a numeirc value that lies between 0-100, relating to how well participants think they will remember something on a later memory test (see #link(<ref-rhodes2015>)[Rhodes, 2015];). As another example, learning outcomes are often measured by looking at accuracy on a final test. To illustrate, consider a memory experiment where participants read a short passage on a specific topic. After a brief distractor task, they take a final memory test with 10 short-answer questions, each worth a different number of points (e.g., question 1 might be worth 4 points, while question 2 might be worth 1 point). Your primary interest is in the total number of correct answers out of the total possible points for each question. This outcome is proportional in nature. How do you analyze this type of data?

While on the surface this may appear as an easy question to answer, the statistical analysis of proportions can present numerous difficulties that are often not taken into consideration. By definition, proportions are limited to numerical values between, and including, 0 and 1, and the variability in the observed proportions usually varies systematically with the mean of the response. It is quite common to analyze proportional outcomes using methods falling under the general linear model (GLM). There are several issues with this approach, however. First, the GLM assumes the residuals in the model are normal distributed. Second, it assumes an unbounded distribution that can extend from -$oo$ to $oo$. Lastly, the GLM assumes constant residuals across varying levels of variables in the model. These assumptions are often violated when dealing with proportional data, which are typically bounded between 0 and 1 and may not follow a normal distribution (#link(<ref-ferrari2004>)[Ferrari & Cribari-Neto, 2004];; #link(<ref-paolino2001>)[Paolino, 2001];). Adopting a model that does not capture your data accurately can have deleterious consequences, such as missing a true effect when it exists (Type 2 error), or mistaking an effect as real when it is not (Type 1 error). A goal for any researcher trying to draw inferences from their data is to fit a model that accurately captures the important features of the data, and has predictive utility (#link(<ref-yarkoni2017>)[Yarkoni & Westfall, 2017];).

The issues related to analyzing proportional data are not new (see (#link(<ref-bartlett1936>)[Bartlett, 1936];)). Luckily, several analysis strategies are available to deal with them. One such approach we highlight here is beta regression (#link(<ref-ferrari2004>)[Ferrari & Cribari-Neto, 2004];; #link(<ref-paolino2001>)[Paolino, 2001];) and some of its alternatives. With the combination of open-source programming languages like R (#link(<ref-R>)[R Core Team, 2024];) and the great community of package developers, it is becoming trivial to run analyses like beta regression. However, adoption of these methods, especially in psychology, is sparse. A quick Web of Science search for a 10 year period spanning 2014-2024 using (TS=(Psychology)) AND TS=(beta regression) as search terms returned fewer than 20 articles. One reason for the lack of adaptation could be the lack of resources available to wider community (but see \[Heiss (#link(<ref-heiss2021>)[2021];); Vuorre (#link(<ref-vuorre2019>)[2019];); \@bendixen2023\]. We attempt to the rectify this herein.

In this article, we plan to (a) give a brief, non-technical overview of the principles underlying beta regression, (b) walk-through an empirical example of applying beta regression using popular frequentist and Bayesian packages in the popular R programming language and (c) highlight the the extensions which are most relevant to researchers in psychology (e.g., zero-inflated, zero-one-inflated, and ordered beta regressions).

To make this tutorial useful, we will use the popular open source programming language R (#link(<ref-R>)[R Core Team, 2024];). We integrate key code chunks into the main text throughout so the reader can follow along. In addition, this manuscript is fully reproducible as it is written with Quarto and is publicly available at this location:.

Because frequentist statistics are still quite popular in psychology we highlight how to perform beta regression using frequentist packages like `betareg` (#link(<ref-betareg>)[Cribari-Neto & Zeileis, 2010];) and `glmmTMB` (#link(<ref-glmmTMB>)[Brooks et al., 2017];) (useful if you have nested/multilevel data, or working with more complex models). We also highlight how to run these models within a Bayesian framework using the `brms` (#link(<ref-brms>)[Bürkner, 2017];) package. Our main goal for this tutorial is for it to be maximally useful regardless of statistical proclivities of the user.

== Beta distribution
<beta-distribution>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Before we discuss beta regession it is important to build up an intution about the beta distribution. Going back to our example from the introduction, our main measure is continuous varying between 0 and 1. Given this, what kind of distribution can be used to fit this data? The beta distribution is perfect for analyzing outcomes like proportions, percentages, and ratios.#footnote[Unlike some other popular distributions (Gaussian, poisson, binomial) the beta distribution is not generally thought of as part of the exponential/GLM family.] The beta distribution has some desirable characteristics that make it ideal for analyzing this type of data: It is continuous, it is limited to numbers that fall between 0 and 1, and it highly flexible—it can take on a number of different distribution shapes. It is important to note that the beta distribution #emph[excludes] numbers that are exactly 0 and exactly 1. That is, it cannot model values that are exactly 0 or 1.

The beta distribution can take on a number of different shapes. The location, skew, and spread of the distribution is controlled by two parameters: #emph[shape1] and #emph[shape2];. `Shape 1` is sometimes called $alpha$ and `shape 2` is sometimes called $beta$. Together these two parameters shape the density curve of the distribution. For example, let’s suppose a participant got 4 out of 6 correct on a test item. We can take the number of correct on that particular test item (4) and divide that by the number of correct (4) + number of incorrect (2) and plot the resulting density curve. Shape1 in this example would be 4 (number of points received). This parameter reflects the number of successes. `Shape2` would be 2–the number of points not received. This parameter reflects the number of failures. Looking at #link(<fig-beta-dist>)[Figure~1] (a) we see the distribution for one of our questions is shifted towards one indicating higher accuracy on the exam.~If we reversed the values of the two parameters, we would get a distribution shifted towards 0 (b), indicating a lower accuracy. By adjusting the values of two parameters, we can get a wide range of distributions (e.g., u-shaped, inverted u-shaped , normal, or uniform). As can be seen, the beta distribution is a distribution of proportions or probabilities.

#figure([
#box(image("beta_regression_draft_files/figure-typst/fig-beta-dist-1.svg"))
], caption: figure.caption(
position: top, 
[
A. Beta distribution with 4 correct and 2 incorrect. B. Beta distribution with 2 correct and 4 incorrect
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-beta-dist>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
However, the canonical parametrization of $alpha$ and $beta$ does not lend itself to the regression framework. Thus, it is quite common to talk about $mu$ and $phi.alt$ instead, where $mu$ represents the mean or average, and $phi.alt$ represents the precision. We can reparamterize $alpha$ and $beta$ into $mu$ and $phi.alt$:

$ [t] upright("Shape 1:") &  & a & = mu phi.alt\
upright("Shape 2:") &  & b & = (1 - mu) phi.alt #h(2em) #h(2em) #h(2em) [t] upright("Mean:") &  & mu & = frac(a, a + b)\
upright("Precision:") &  & phi.alt & = a + b $ \

The variance is a function of $mu$ and $phi.alt$:

$ frac(mu dot.op (1 - mu), 1 + phi.alt) $

== Beta regression
<beta-regression>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
We can use regression to model the $mu$ (mean) and $phi.alt$ (dispersion) parameters of a beta-distributed response variable. Beta regression is a joint modeling approach that utilizes a logit link function to model the mean of the response variable as a function of the predictor variables. Another link function, commonly the log link, is used to model the dispersion parameter. The application of these links ensures the parameters stay within their respective bounds, with $mu$ between 0 and 1 and $phi.alt$ strictly positive. Overall, the beta regression approach respects the bounded nature of the data and allows for heteroskedasticity, making it highly appropriate for data that represents proportions or rates.

= Example
<example>
== Data and Methods
<data-and-methods>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Now we have built up an intuition about the beta distribution we can start to analyze some data. The principles of beta regression are best understood in the context of a real data set. The example we are gonna use comes from the learning and memory literature. A whole host of literature has shown extrinsic cues like fluency (i.e., how easy something is to process) can influence metamemory (i.e., how well we think we will remember something). As an interesting example, a line of research has focused on instructor fluency and how that influences both metamemory and actual learning. When an instructor uses lots of non-verbal gestures, has variable voice dynamics/intonation, is mobile about the space, and includes appropriate pauses when delivering content, participants preceieve them as more fluent, but it does not influence actual memory performance, or what we learn from them (#link(<ref-carpenter2013>)[Carpenter et al., 2013];; #link(<ref-toftness2017>)[Toftness et al., 2017];; #link(<ref-witherby2022>)[Witherby & Carpenter, 2022];). While fluency of instuctor has not been found to impact actual memory across several studies, Wilford et al. (#link(<ref-wilford2020>)[2020];) found that it can. In several experiments, Wilford et al. (#link(<ref-wilford2020>)[2020];) showed that when participants watched multiple videos of a fluent vs.~a disfluent instructor (here two videos as opposed to one), they remembered more information on a final test. Given the interesting, and contradictory results, we chose this paper to highlight. In the current tutorial we are going to re-analyze the final recall data from Wilford et al.~(2021; Experiment 1a). All their is data is open and available here: #link("https://osf.io/6tyn4/");.

Accuracy data is widely used in psychology and is well suited for beta regression. Despite this, it is common to treat accuracy data as continuous and unbounded, and analyze the resulting proportions using methods that fall under the general linear model. Below we will reproduce the analysis conducted by Wilford et al. (#link(<ref-wilford2020>)[2020];) (Experiment 1a) and then re-analyze it using beta regression. We hope to show how beta regression and its extensions can be a more powerful tool in making inferences about your data.

Wilford et al. (#link(<ref-wilford2020>)[2020];) (Expt 1a) presented participants with two short videos on the genetics of calico cats and why skin wrinkles. Participants viewed either disfluent or fluent versions of these videos.#footnote[See an example of the fluent video here: #link("https://osf.io/hwzuk");. See an example of the disfluent video here: #link("https://osf.io/ra7be");.] For each video, metamemory was assessed using JOLs. JOLs require participants to rate an item on scale between 0-100 with 0 representing the item will not be remembered and a 100 representing they will definitely remember the item. In addition, other questions about the instructor were assessed and how much they learned. After a distractor task, a final free recall test was given were participants had to recall as much information about the video as they could in 3 minutes. Participants could score up to 10 points for each video. Here we will only being looking at the final recall data, but you could also analyze the JOL data as well with a beta regression.

== Reanalysis of Wilford et al.~Experiment 1a
<reanalysis-of-wilford-et-al.-experiment-1a>
=== GLM approach
<glm-approach>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
In Experiment 1a, Wilford et al. (#link(<ref-wilford2020>)[2020];) only used the first time point and compared fluent and disfluent conditions with a #emph[t];-test. In our re-analysis, we will also run a #emph[t];-test, but in a regression context. This allows for easier generalization to the beta regression approach. Specifically, we will examine accuracy on final test (because the score was on a 10 point scale we multiplied each value by 10 and divided by 100 to get a proportion) as our DV and Condition. Fluency will be dummy coded with the fluent level as our reference level.

=== Load packages and data
<load-packages-and-data>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
As a first step, we will load the necessary packages along with the data we will be using. While we load all the necessary packages here, we also highlight when packages are needed as code chunks are run.

#block[
```r
# packages needed
library(tidyverse) # tidy functions/data wrangling/viz
library(betareg) # run beta regression 
library(glmmTMB) # zero inflated beta
library(easystats)
library(gghalves)
library(ggbeeswarm)       # Special distribution-shaped point jittering
library(scales) # percentage
library(tinytable) # tables
library(marginaleffects) # marginal effects
library(extraDistr)       # Use extra distributions like dprop()
library(brms) # bayesian models

options(scipen = 999) # get rid of scienitifc notation
```

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Next, we load in our data, rename the columns to make them more informative, and transform the data. Here we transform accuracy so it is a proportion by multiplying each score by 10 and dividing by 100. Finally, we dummy code the `Fluency` variable setting the fluent condition to 0 and disfluent condition to 1. A small version of the dataset can be seen in #link(<tbl-dataset>)[Table~1] along with a data dictionary in #link(<tbl-columnkey>)[Table~2]

```r
# Read the CSV file located in the "MS/data" directory and store it in a dataframe
fluency_data <- read.csv(here::here("MS/data/miko_data.csv")) %>%
  
  # Rename the columns for better readability
  rename(
    "Participant" = "ResponseID", # Rename "ResponseID" to "Participant"
    "Fluency" = "Condition",      # Rename "Condition" to "Fluency"
    "Time" = "name",              # Rename "name" to "Time"
    "Accuracy" = "value"          # Rename "value" to "Accuracy"
  ) %>%
  
  # Transform the data
  mutate(
    Accuracy = Accuracy *10 / 100, # Convert Accuracy values to proportions
    Fluency = ifelse(Fluency == 1, "Fluent", "Disflueny"), # rename levels 
    Fluency_dummy = ifelse(Fluency == "Fluent", 0, 1),  # Recode
    #Fluency: 1 becomes 0, others become 1 
    Fluency_dummy = as.factor(Fluency_dummy) # turn fluency cond to dummy code

  ) %>%
  
  filter(Time=="FreeCt1AVG") %>% # only choose first time point
  
  # Drop the column "X" and "time" from the dataframe
  select(-X, -Time)  %>%
  
  # move columns around
  
  relocate(Accuracy, .after = last_col())
  

# Display the first few rows of the modified dataframe
head(fluency_data) %>%
  tt()
```

#figure([
#[
#let nhead = 1;
#let nrow = 6;
#let ncol = 4;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 7, start: 0, end: 4, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 4, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 4, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Participant], [Fluency], [Fluency_dummy], [Accuracy],
    ),

    // tinytable cell content after
[R_00Owxl28JtOADxn], [Fluent], [0], [0.45],
[R_1DZHq7wW6PhBu7l], [Fluent], [0], [0.30],
[R_1FfS9t7o3G2waGp], [Fluent], [0], [0.40],
[R_1gqH4bLsvaqpRRZ], [Fluent], [0], [0.15],
[R_1i4M7ZdpTcywgbq], [Fluent], [0], [0.50],
[R_1NyRhBnAB5J2S3r], [Fluent], [0], [0.70],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
position: top, 
[
First few rows from our dataset
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-dataset>


#figure([
#[
#let nhead = 1;
#let nrow = 4;
#let ncol = 2;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 5, start: 0, end: 2, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 2, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 2, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Column], [Key],
    ),

    // tinytable cell content after
[Participant  ], [Participant ID number           ],
[Fluency      ], [Fluent vs. Disfluent            ],
[Fluency_dummy], [Fluent: 0; Disfluent: 1         ],
[Accuracy     ], [Proportion recalled (idea units)],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
position: top, 
[
Columns and values from the dataset
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-columnkey>


== OLS regression
<ols-regression>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
We first fit a regression model using the `lm`function to the data looking at final test accuracy (`Accuracy`) as a function of instructor fluency (`fluency_dummy1`). In #link(<fig-flu1>)[Figure~2];, we see that accuracy is higher in the fluent condition vs.~the disfluent condition. Is this difference reliable?

#figure([
#box(image("beta_regression_draft_files/figure-typst/fig-flu1-1.svg"))
], caption: figure.caption(
position: top, 
[
Raincloud plot of proprotion recalled on final test as a function of Fluency
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-flu1>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Below is the code needed to fit the model in R.

#block[
```r
# fit ols reg
ols_model <- lm(Accuracy~Fluency_dummy, data=fluency_data)
```

]
```r
# for regression model 
ols_model_new <- model_parameters(ols_model)


ols_model_new %>%
 tt(digits = 2) %>%
    format_tt(j = "p", fn = scales::label_pvalue()) %>%
  format_tt(escape = TRUE)
```

#figure([
#[
#let nhead = 1;
#let nrow = 2;
#let ncol = 9;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 3, start: 0, end: 9, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 9, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 9, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Parameter], [Coefficient], [SE], [CI], [CI_low], [CI_high], [t], [df_error], [p],
    ),

    // tinytable cell content after
[(Intercept)], [ 0.341], [0.031], [0.95], [ 0.28], [ 0.40244], [11], [94], [\<0.001],
[Fluency_dummy1], [\-0.084], [0.042], [0.95], [\-0.17], [\-0.00058], [\-2], [94], [0.048],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
position: top, 
[
OLS regression model coefficents
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-ols>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Focusing on output from our regression analysis in #link(<tbl-ols>)[Table~3] , we see the that there is a significant effect of Fluency (`Fluency_dummy`), b = -0.084 , SE = 0.042 , 95% CIs = \[-0.168,-0.001\], p = 0.048. This is exactly what Wilford et al. (#link(<ref-wilford2020>)[2020];) found in their paper.

== Beta regression approach
<beta-regression-approach>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Using a traditional approach, we observed instructor fluency impacts actual learning. Keep in mind the traditional approach assumes normality of residuals and homoscadacity. Does the model meet those assumptions? Using `easystats` (#link(<ref-easystats>)[Lüdecke et al., 2022];) and the `check_model` function, we can easily assess this. In #link(<fig-ols-assump>)[Figure~3] , we can see there are some issues with our model. Specifically, there is appears to violations of normality and homoscakdacity.

#figure([
#box(image("beta_regression_draft_files/figure-typst/fig-ols-assump-1.svg"))
], caption: figure.caption(
position: top, 
[
Assumption checks for OLS model
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-ols-assump>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
One solution is to run a beta regression model. Below we fit a beta regression using the `betareg` package (#link(<ref-betareg>)[Cribari-Neto & Zeileis, 2010];). This a popular package for running frequentist beta regressions.

#block[
```r
# load betareg package
library(betareg)
```

]
#block[
```r
# running beta model error
beta_model<-betareg(Accuracy~Fluency_dummy, data=fluency_data)
```

#block[
```
Error in betareg(Accuracy ~ Fluency_dummy, data = fluency_data): invalid dependent variable, all observations must be in (0, 1)
```

]
]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
When you run the above model, an error will appear: `Error in betareg(Accuracy ~ Fluency_dummy, data = fluency_data) : invalid dependent variable, all observations must be in (0, 1)`. If your remember, the beta distribution can model responses in the interval \[0-1\], but not exactly 0 or 1. We need make sure there are no zeros and ones in our dataset.

#figure([
#[
#let nhead = 1;
#let nrow = 2;
#let ncol = 2;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 3, start: 0, end: 2, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 2, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 2, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Accuracy], [n],
    ),

    // tinytable cell content after
[0], [9],
[1], [1],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
position: top, 
[
Amount of zeros and ones in our dataset
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-01s>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Looking at #link(<tbl-01s>)[Table~4];, we have 9 rows with accuracy of 0, and 1 row with an accuracy of exactly 1. To run a beta regression, we can employ a little hack. We can nudge our 0s towards .01 and 1s to .99 so they fall within the interval of \[0-1\].#footnote[In the newest version of betareg you can model data inclusive 0-1 by including a xdist argumement.]

#block[
```r
# transform 0 to 0.1 and 1 to .99
data_beta <- fluency_data %>% 
    mutate(Accuracy = ifelse(Accuracy == 0, .01, ifelse(Accuracy == 1, .99, Accuracy)))
```

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Let’s fit the model again.

#block[
```r
# fit beta model without 0s and 1s in our dataset 

beta_model<-betareg(Accuracy~Fluency_dummy, data=data_beta)
```

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
No errors this time! Now, Let’s interpret the results of our beta regression. #link(<tbl-beta-cond>)[Table~5] includes the output of our beta regression model for the conditional or $mu$ parameter

#figure([
#[
#let nhead = 1;
#let nrow = 2;
#let ncol = 9;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 3, start: 0, end: 9, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 9, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 9, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Parameter], [Coefficient], [SE], [CI], [CI_low], [CI_high], [z], [df_error], [p],
    ),

    // tinytable cell content after
[(Intercept)], [\-0.59], [0.14], [0.95], [\-0.88], [\-0.31 ], [\-4.1], [Inf], [\<0.001],
[Fluency_dummy1], [\-0.45], [0.2 ], [0.95], [\-0.83], [\-0.061], [\-2.3], [Inf], [0.023],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
position: top, 
[
Model summary for the mu parameter in beta regression model
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-beta-cond>


=== Model parameters
<model-parameters>
==== $mu$ component.
<mu-component>
Looking at the model output in #link(<tbl-beta-cond>)[Table~5];, the first set of coefficients represents how factors influence the $mu$ parameter, which is the mean of the beta distribution. These coefficients are interpreted on the scale of the logit link function, meaning they represent changes in the log-odds of the mean proportion. The intercept term represents the log odds of the mean on accuracy for the fluent instructor condition which we coded as the reference. Here being in the fluent condition translates to a log odds of -0.593. The fluency coefficient represents the difference between the fluency and disfluency conditions. That is, watching a fluent instructor leads to higher recall than watching a disfluent instructor, b = -0.447 , SE = 0.197 , 95% CIs = \[-0.833,-0.061\], p = 0.023.

===== Predicted probabilities.
<predicted-probabilities>
Parameter estimates are usually difficult to intercept on their own. Instead we should discuss the effects of the predictor on the actual outcome of interest (in this case the 0-1 scale). The logit link allows us to transform back and forth between log-odds and probabilities. By using the inverse of the logit, we can easily transform coefficients to obtain proportions or percentages. In a simple case, we can do this manually, but when we have many moving pieces it can get quite complicated. Thankfully, there is a package called #strong[`marginaleffects`] (#link(<ref-marginaleffects>)[Arel-Bundock, 2024];) that can help us extract the probabilities quite easily.#footnote[`ggeffects` is another great package to extract marginal effects and plot (#link(<ref-ggeffects-2>)[Lüdecke, 2018];)] For a more detailed explanation of the package please check out: #link("https://marginaleffects.com/");. To get the proportions for each of our categorical predictors we can use the function from the package called `avg_predictions`.

#block[
```r
#load marginaleffects package
library(marginaleffects)
```

]
```r
# get the predicted probablities for each level of fluency 
avg_predictions(beta_model, variables="Fluency_dummy") %>% 
  select(-s.value) %>%
  tt(digits = 2) %>%
    format_tt(j = "p", fn = scales::label_pvalue()) %>%
  format_tt(escape = TRUE)
```

#figure([
#[
#let nhead = 1;
#let nrow = 2;
#let ncol = 7;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 3, start: 0, end: 7, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 7, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 7, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Fluency_dummy], [estimate], [std.error], [statistic], [p.value], [conf.low], [conf.high],
    ),

    // tinytable cell content after
[0], [0.36], [0.033], [10.8], [\<0.001], [0.29], [0.42],
[1], [0.26], [0.027], [ 9.6], [\<0.001], [0.21], [0.31],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
position: top, 
[
Predicted probablities for fluency
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-predict-prob>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Looking at #link(<tbl-beta-cond>)[Table~5];, we see that both values in the estimate column are negative, which indicates that probability is below 50%. Looking at the predicted probabilities confirms this. For the `Fluency` factor, we can interpret the estimate column in terms of proportions or percentages. That is, participants who watched the fluency video scored on average 36% on the final exam compared to 29% for those who watched the disfluency video.

===== Marginal effects.
<marginal-effects>
We can also examine changes in predicted probabilities for variations or small changes in an independent variable. This is called a marginal effect. There are different types of marginal effects, and various packages calculate them differently. Since we will be using the `marginaleffects` package for this tutorial, we will focus on the average marginal effect (AME), which is used by default in the `marginaleffects` package. The AME is the predicted change in the outcome for a very small change in the independent variable. In the `marginaleffects` package this involve generating predictions for each row of the original data then averaging these predictions. One effect size measure we can calculate with categorical variables is the risk difference, which is the discrete difference between the average marginal effect of one condition or group and that of another condition or group. In the `marginaleffects` package, we can use the function `avg_comparisons` to obtain this metric. This function can also be used to get other popular effect size metrics, such as odds ratios and risk ratios.

```r
# get risk difference 
beta_avg_comp<- avg_comparisons(beta_model, comparison= "difference") 

beta_avg_comp %>%
  select(-predicted_lo,-predicted_hi,-s.value, -predicted)%>%
   tt(digits = 2) %>%
    format_tt(j = "p", fn = scales::label_pvalue()) %>%
  format_tt(escape = TRUE)
```

#figure([
#[
#let nhead = 1;
#let nrow = 1;
#let ncol = 8;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 2, start: 0, end: 8, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 8, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 8, stroke: 0.1em + black),

    table.header(
      repeat: true,
[term], [contrast], [estimate], [std.error], [statistic], [p.value], [conf.low], [conf.high],
    ),

    // tinytable cell content after
[Fluency_dummy],
[mean(1) \- mean(0)],
[\-0.095],
[0.042],
[\-2.3],
[0.023],
[\-0.18],
[\-0.013],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
position: top, 
[
Margianl effects (risk difference) for Fluency factor
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-ame1>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Interpreting the output in #link(<tbl-ame1>)[Table~7];, we see in the fluent condition, participants who watched a fluent instructor scored 9% higher on the final recall test than participants who saw the disfluent instructor. This difference is reliable, b= -0.0948152, SE = 0.0418028, 95 % CIs \[-0.1767471, -0.0128833 \], p = 0.0233196.

We can also get the odds ratio (see #link(<tbl-or>)[Table~8];).

```r
# get odds ratios as an example
avg_comparisons(beta_model, comparison = "lnoravg",
    transform = "exp") %>%
  select(-predicted_lo,-predicted_hi,-s.value, -predicted) %>% 
  tt() %>%
  format_tt(digits=3)
```

#figure([
#[
#let nhead = 1;
#let nrow = 1;
#let ncol = 6;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 2, start: 0, end: 6, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 6, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 6, stroke: 0.1em + black),

    table.header(
      repeat: true,
[term], [contrast], [estimate], [p.value], [conf.low], [conf.high],
    ),

    // tinytable cell content after
[Fluency_dummy],
[ln(odds(1) / odds(0))],
[0.639],
[0.0231],
[0.435],
[0.941],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
position: top, 
[
Margianl effects (odds ratio) for Fluency factor
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-or>


==== Plotting.
<plotting>
We can easily plot the $mu$ parameter part of model using the `marginaleffects` package and the `plot_predictions` function (see #link(<fig-plot-pre>)[Figure~4];).

```r
plot_predictions(beta_model, condition="Fluency_dummy") +
  theme_lucid(base_size=14) + 
  scale_x_discrete(breaks=c("0","1"),
        labels=c("Fluent", "Disfluent")) + 
  scale_y_continuous(labels = label_percent())
```

#figure([
#box(image("beta_regression_draft_files/figure-typst/fig-plot-pre-1.svg"))
], caption: figure.caption(
position: top, 
[
Predicted probablities for fluency factor
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-plot-pre>


==== Precision ($phi.alt$) component.
<precision-phi-component>
The other component we need to pay attention to is the dispersion or precision parameter coefficients labeled as `phi` in #link(<tbl-phi>)[Table~9] The $phi.alt$ parameter tells us how precise our estimate is. Specifically, $phi.alt$ in beta regression tells us about the variability of the response variable around its mean. Specifically, a higher dispersion parameter indicates a narrower distribution, reflecting less variability. Conversely, a lower dispersion parameter suggests a wider distribution, reflecting greater variability.

Understanding the dispersion parameter helps us gauge the precision of our predictions and the consistency of the response variable. In `beta_model` we only modeled the dispersion of the intercept. When $phi.alt$ is not specified, the intercept is modeled by default.

#block[
```r
# fit beta regression model using betareg 

beta_model<-betareg(Accuracy~Fluency_dummy, data=data_beta)
```

]
```r
# get the precision paramter 
beta_model %>%
  model_parameters(component = "precision") %>%
   tt(digits = 2) %>%
    format_tt(j = "p", fn = scales::label_pvalue()) %>%
  format_tt(escape = TRUE)
```

#figure([
#[
#let nhead = 1;
#let nrow = 1;
#let ncol = 9;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 2, start: 0, end: 9, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 9, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 9, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Parameter], [Coefficient], [SE], [CI], [CI_low], [CI_high], [z], [df_error], [p],
    ),

    // tinytable cell content after
[(phi)],
[3.4],
[0.46],
[0.95],
[2.5],
[4.3],
[7.5],
[Inf],
[\<0.001],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
position: top, 
[
Beta model output of the $phi.alt$ parameter
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-phi>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The intercept under the precision heading is not that interesting. To make things a bit more interesting, let’s model the dispersion of the `Fluency`factor—this allows dispersion to differ between the fluent and disfluent conditions. To do this we add a vertical bar to our `betareg` function which allows us to model the dispersion of any factor to the right of it. In the below model, `beta_model_dis`, we model the precision of the `Fluency` factor.

#block[
```r
# add disp/percison for fluency 
beta_model_dis<-betareg(Accuracy~Fluency_dummy | Fluency_dummy, data=data_beta)
```

]
```r
beta_model_dis  %>%
  model_parameters(component = "precision")%>%
  tt(digits = 2) %>%
    format_tt(j = "p", fn = scales::label_pvalue()) %>%
  format_tt(escape = TRUE)
```

#figure([
#[
#let nhead = 1;
#let nrow = 2;
#let ncol = 9;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 3, start: 0, end: 9, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 9, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 9, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Parameter], [Coefficient], [SE], [CI], [CI_low], [CI_high], [z], [df_error], [p],
    ),

    // tinytable cell content after
[(Intercept)], [ 1.85], [0.2 ], [0.95], [ 1.5], [ 2.24], [ 9.2], [Inf], [\<0.001],
[Fluency_dummy1], [\-0.94], [0.27], [0.95], [\-1.5], [\-0.41], [\-3.5], [Inf], [\<0.001],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
position: top, 
[
Beta model output with $phi.alt$ parameter for fluency factor
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-phi-beta>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Looking at the precision parameter coefficient for Fluency in #link(<tbl-phi-beta>)[Table~10];, it is important to note that this estimate is on the logit scale, instead the estimates are logged (this is only the case when more than the intercept is modeled). To interpret them on the original scale, we can exponent the log-transformed value—this transformation gets us back to our original scale. We get only the dispersion parameter by setting by setting the `component` argument to `precision` in `model_parameters`. We can also get the original value by including the `exponentiate = TRUE`.

#figure([
#[
#let nhead = 1;
#let nrow = 2;
#let ncol = 9;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 3, start: 0, end: 9, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 9, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 9, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Parameter], [Coefficient], [SE], [CI], [CI_low], [CI_high], [z], [df_error], [p],
    ),

    // tinytable cell content after
[(Intercept)], [6.33], [1.27], [0.95], [4.27], [9.38], [ 9.2], [Inf], [\<0.001],
[Fluency_dummy1], [0.39], [0.11], [0.95], [0.23], [0.66], [\-3.5], [Inf], [\<0.001],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
Precision paramter coeficients for beta regression model

], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-precison-exp>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
In #link(<tbl-precison-exp>)[Table~11];, The $phi.alt$ intercept represents the precision of the fluent condition. The $phi.alt$ coefficient for `Fluency_dummy1` represents the change in that precision for the fluent instructors vs.~disfluent instructors. The effect is reliable, b = -0.246 , SE = 0.198 , 95% CIs = \[-0.634,0.143\], p = 0.215.

Now, we have all the parameters to draw two different distributions of our outcome, split by fluency of the instructor. Let’s plot these two predicted distributions on top of the true underlying data and see how well they fit. In #link(<fig-dispersion-viz>)[Figure~5] and #link(<fig-no-dispersion-viz>)[Figure~6] and we can see how the distribution changes when we include a dispersion parameter for Fluency.

#block[
#callout(
body: 
[
Horrible fit. Why?

]
, 
title: 
[
Note
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
)
]
#figure([
#box(image("beta_regression_draft_files/figure-typst/fig-dispersion-viz-1.svg"))
], caption: figure.caption(
position: top, 
[
Distributional outcomes of Fluency with disperison parameter included
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-dispersion-viz>


#figure([
#box(image("beta_regression_draft_files/figure-typst/fig-no-dispersion-viz-1.svg"))
], caption: figure.caption(
position: top, 
[
Distributional outcomes of Fluency with no disperison parameter modeled
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-no-dispersion-viz>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Note how the whole distribution changes when allow precision to differ across levels of `Fluency`. The data doesn’t fit the underlying distribution very well. Despite this, this makes clear the importance of including a precision parameter. A critical assumption of the GLM is homoscedasticity, which means constant variance of the errors. Here we see one of the benefits of a beta regression model. We can include a dispersion parameter for Fluency. Properly accounting for dispersion is crucial because it impacts the precision of our mean estimates and, consequently, the significance of our coefficients. The inclusion of dispersion in the our model changed the statistical significance of the $mu$ coefficient. This suggests that failing to account for the dispersion of the variables might lead to biased estimates. This highlights the potential utility of an approach like beta regression over a traditional GLM (regression or ANOVA approach), as beta regression can explicitly model dispersion and address issues of heteroscedasticity.

We wont always need to include dispersion parameters for each of our variables. it is preferable to conduct a very simple likelihood ratio test (LRT) to examine if we need to include dispersion into our model. To test this we use the `test_likelihoodratio` from the `easystats` ecosystem (#link(<ref-easystats>)[Lüdecke et al., 2022];).

```r
beta_model <- betareg(Accuracy~Fluency_dummy , data=data_beta)

beta_model_dis<-betareg(Accuracy~Fluency_dummy | Fluency_dummy, data=data_beta)


LRT<-test_likelihoodratio(beta_model, beta_model_dis)

LRT %>%
  tt() %>%
  format_tt(digits=3)
```

#figure([
#[
#let nhead = 1;
#let nrow = 2;
#let ncol = 6;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 3, start: 0, end: 6, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 6, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 6, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Name], [Model], [df], [df_diff], [Chi2], [p],
    ),

    // tinytable cell content after
[beta_model], [betareg], [3], [], [], [],
[beta_model_dis], [betareg], [4], [ 1], [11.5], [0.000689],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-LRT>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
According to the results of our LRT in #link(<tbl-LRT>)[Table~12] , we would want to model the precision for fluency as the test is significant, $Delta$$chi^2$ = 11.5193612 , #emph[p] \< .001.

== Bayesian implementation of beta regression
<bayesian-implementation-of-beta-regression>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
We can also fit beta regression models within a Bayesian framework. Adopting a Bayesian framework often provides more flexibility and allows us to quantity uncertainty around our estimates which makes it more powerful than the frequentist alternative. For the purposes of this tutorial, we will not be getting into the minutiae of Bayesian data analysis (i.e., setting informative priors, MCMC sampling, etc,). For a more in-depth look into Bayesian data analysis I refer the reader to XXX.

For the following analyses we will be using default priors provided by `brms`. This will get us something tantamount to a frequent analysis most of the readers are used to seeing.

To fit our Bayesian models, we will be using a Bayesian package called `brms` (#link(<ref-brms>)[Bürkner, 2017];) . b`rms` is a powerful and flexible Bayesian regression modeling package that offers built in support for the beta distribution and some of the alternatives we discuss in this tutorial.

We can recreate the beta model from `betareg` in `brms` easily. Instead of using the `|` operator to specify different parameters, we model each parameter independently. Recall we are fitting two parameters— $mu$ and $phi.alt$. We can easily do this by using the `bf` function from `brms`. `bf()` facilitates the specification of several sub-models within the same formula call. We fit two formulas, one for $mu$ and one for $phi.alt$ and store it in `model_beta_bayes`. Here we allow precision to vary as a fucntion of Fluency.

#block[
```r
#load brms and cmdstanr
library(brms)
library(cmdstanr) # Use the cmdstanr backend for Stan because it's faster and more modern than
  # the default rstan You need to install the cmdstanr package first
  # (https://mc-stan.org/cmdstanr/) and then run cmdstanr::install_cmdstan() to
  # install cmdstan on your computer.
options(marginaleffects_posterior_center = mean)
# get mean instead of median in marginaleffects
```

]
#block[
```r
# fit model with mu and phi
model_beta_bayes <- bf(Accuracy  ~ Fluency_dummy, # fit mu 
     phi ~ Fluency_dummy) # fit phi 
```

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
We can then pass `model_beta_bayes` to the `brm` function and set the model family to the beta distribution, which is native to our model using the `brm` function. We also set a bunch of arguments to speed up the fitting of the models, which we will not explain herein.

#figure([
#[
#let nhead = 1;
#let nrow = 4;
#let ncol = 8;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 5, start: 0, end: 8, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 8, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 8, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Parameter], [Mean], [CI], [CI_low], [CI_high], [pd], [Rhat], [ESS],
    ),

    // tinytable cell content after
[b_Intercept], [-0.678], [0.95], [-0.909], [-0.439], [1], [0.999], [4653],
[b_phi_Intercept], [ 1.808], [0.95], [ 1.396], [ 2.172], [1], [1], [3423],
[b_Fluency_dummy1], [-0.247], [0.95], [-0.66], [ 0.153], [0.893], [1], [3021],
[b_phi_Fluency_dummy1], [-0.924], [0.95], [-1.439], [-0.41], [1], [0.999], [3345],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
position: top, 
[
Parameter estimates for beta regression using `brms`
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-beta-brms>


=== Model parameters
<model-parameters-1>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Parameter estimates for the `brms` fitted beta regression model are labeled in #link(<tbl-beta-brms>)[Table~13];.#footnote[We have chain diagnostics included like Rhat and ESS which indicates how the MCMC sampling performed. For more information check out Gelman et al., 2013; Kruschke, 2014; McElreath, 2020)] To make the output more readable, each model parameter is labeled with a prefix before the variable name, except for the $mu$ parameter, which takes same name as the variables in your model. Comparing results with \`#raw("betareg`");in `model_beta`, our results are very similar. Additionally, the parameters can be interpreted in a similar manner and we can use `marginaleffects` to extract marginal effects and risk difference. #footnote[It is important to note that these transformations should be applied to draws from the posterior distribution. `Marginaleffects` does this under the hood, but other packages might not.];In contrast to frequentist models, Bayesian models allow us to make probabilistic inferences. Contrary to frequentist models, there are no #emph[p];-values to interpret in Bayesian models. There is a metric in the table that is included with models fit with `easystats` and `bayestestr` called probability of direction (pd) that gives an indication of how much of the posterior distribution estimate is in one direction. This is correlated with #emph[p];-values (#link(<ref-makowski2019>)[Makowski, Ben-Shachar, & Lüdecke, 2019];; #link(<ref-makowski2019a>)[Makowski, Ben-Shachar, Chen, et al., 2019];). The two-sided #emph[p];-value of respectively #strong[.1];, #strong[.05];, #strong[.01] and #strong[.001] would correspond approximately to a #emph[pd] of #strong[95%];, #strong[97.5%];, #strong[99.5%] and #strong[99.95%];. What is sometimes done to judge statistical significance of an effect is to examine the 95% credible interval to see if it includes 0–if it does not then the effect can be said to be significant. In the table below the 95% credible intervals are located in the CI\_low and CI\_high columns. The results are similar to what we found with \`#raw("betareg`");in `model_beta`.

=== Posterior predictive check
<posterior-predictive-check>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The `pp_check` function allows us to examine the fit between our data and the model. In #link(<fig-post-pred>)[Figure~7];, the x-axis represents the possible range of outcome values and the y-axis represents the density of each outcome value. Ideally, the predictive draws (the lighly blue lines) should show reasonable resemblance with the observed data (dark blue line). We see it does a pretty good job capturing the data.

```r
pp_check(beta_brms,ndraws = 100)
```

#figure([
#box(image("beta_regression_draft_files/figure-typst/fig-post-pred-1.svg"))
], caption: figure.caption(
position: top, 
[
Posterior predictive check for our beta model with 100 draws
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-post-pred>


=== Predicted probabilities and marginal effects
<predicted-probabilities-and-marginal-effects>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Predicted probabilities (#link(<tbl-brms-pred-prob>)[Table~14];) and marginal effects (#link(<tbl-brms-marg>)[Table~15];) can be computed similarly to our model fit with `betareg`.

```r
avg_predictions(beta_brms, variables = "Fluency_dummy") %>%
  tt(digits=3)
```

#figure([
#[
#let nhead = 1;
#let nrow = 2;
#let ncol = 4;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 3, start: 0, end: 4, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 4, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 4, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Fluency_dummy], [estimate], [conf.low], [conf.high],
    ),

    // tinytable cell content after
[0], [0.337], [0.287], [0.392],
[1], [0.285], [0.223], [0.354],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-brms-pred-prob>


```r
# risk difference
beta_brms  %>% 
  avg_comparisons(variables = "Fluency_dummy") %>%
   select(-predicted_lo,-predicted_hi, -predicted, -tmp_idx) %>%
  tt(digits=3)
```

#figure([
#[
#let nhead = 1;
#let nrow = 1;
#let ncol = 5;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 2, start: 0, end: 5, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 5, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 5, stroke: 0.1em + black),

    table.header(
      repeat: true,
[term], [contrast], [estimate], [conf.low], [conf.high],
    ),

    // tinytable cell content after
[Fluency_dummy],
[mean(1) - mean(0)],
[-0.0522],
[-0.137],
[0.0337],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-brms-marg>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
In #link(<tbl-brms-marg>)[Table~15];, the risk difference in predicted outcomes is 0.05, which is roughly what we found before with our frequentist model. The 95% credible interval includes zero so we can state the fluency effect is not statistically significant.

=== Plotting
<plotting-1>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Similar to our frequentist model, we can use `plot_predictions` to plot our model on the original scale (see #link(<fig-plot-brms>)[Figure~8];)

```r
plot_predictions(beta_brms, condition="Fluency_dummy") + theme_lucid(base_size = 14) +
  scale_x_discrete(breaks=c("0","1"),
        labels=c("Fluent", "Disfluent")) + 
scale_y_continuous(labels = label_percent()) + 
    labs(x="Fluency")
```

#figure([
#box(image("beta_regression_draft_files/figure-typst/fig-plot-brms-1.svg"))
], caption: figure.caption(
position: top, 
[
Predicted probablities for fluency with 95% credible intervals
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-plot-brms>


= Zero-inflated beta (ZIB) regression
<zero-inflated-beta-zib-regression>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
A limitation of the beta regression model is it can can only model values between 0 and 1, but not 0 or 1. In our dataset we have 9 rows with `Accuracy` equal to zero.

To use the beta distribution we nudged our zeros to 0.01–which is never a good idea in practice. In our case it might be important to model this, as fluency of instructor might be an important factor in predicting the zeros in our model. Luckily, there is a model called the zero-inflated beta (ZIB) model that takes into account the structural 0s in our data. We’ll still model the 𝜇 and 𝜙 (or mean and precision) of the beta distribution, but now we’ll also add one new special parameter: 𝛼. With zero-inflated regression, we’re actually modelling a mixture of data-generating process. The $alpha$ parameter uses a logistic regression to model whether the data is 0 or not. Below we fit a model called `beta_model_0` using the `glmmTMB` package. The `betareg` model cannot model zero-inflated data. In the `glmmTMB` function, we can model the zero inflation by including an argument called `ziformula`. This allows us to model the new parameter $alpha$. Let’s fit a model where there is a zero-inflated component for `Fluency`.

#block[
```r
beta_model_0<-glmmTMB(Accuracy~Fluency_dummy, disp=~Fluency_dummy,  ziformula = ~ Fluency_dummy, data=data_beta_0, family=beta_family(link="logit"))
```

]
=== Model parameters
<model-parameters-2>
```r
# use model_parameters to get the summary coefs
model_zi <- model_parameters(beta_model_0) 

model_zi %>% 
   tt(digits = 2)
```

#figure([
#[
#let nhead = 1;
#let nrow = 6;
#let ncol = 11;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 7, start: 0, end: 11, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 11, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 11, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Parameter], [Coefficient], [SE], [CI], [CI_low], [CI_high], [z], [df_error], [p], [Component], [Effects],
    ),

    // tinytable cell content after
[(Intercept)   ], [-0.631], [0.11], [0.95], [-0.84 ], [-0.42], [-5.91], [Inf], [0.000000003360855240436967], [conditional  ], [fixed],
[Fluency_dummy1], [-0.031], [0.18], [0.95], [-0.39 ], [ 0.33], [-0.17], [Inf], [0.863437422801825782414653], [conditional  ], [fixed],
[(Intercept)   ], [-3.761], [1.01], [0.95], [-5.744], [-1.78], [-3.72], [Inf], [0.000200636415662653949318], [zero_inflated], [fixed],
[Fluency_dummy1], [ 2.056], [1.08], [0.95], [-0.064], [ 4.18], [ 1.9 ], [Inf], [0.057381635126509067390543], [zero_inflated], [fixed],
[(Intercept)   ], [ 2.07 ], [0.2 ], [0.95], [ 1.669], [ 2.47], [10.11], [Inf], [0.000000000000000000000005], [dispersion   ], [fixed],
[Fluency_dummy1], [-0.85 ], [0.28], [0.95], [-1.402], [-0.3 ], [-3.02], [Inf], [0.002535829591057242073104], [dispersion   ], [fixed],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-beta-model-zero>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
#link(<tbl-beta-model-zero>)[Table~16] provides a summary of the output for out. As before, the 𝜇 parameter coefficients under the conditional component are on the logit scale; while 𝜙 parameter coefficients under the precision header are on the log scale. In addition, the parameters under the zero-inflated component are on the logit scale. Looking at the $mu$ part of the model, there is no significant effect for `Fluency`, b = -0.031 , SE = 0.198 , 95% CIs = \[-0.634,0.143\], p = 0.215 . However, for the zero-inflated part of the model, the `Fluency` predictor is significant, b = -0.031 , SE = 0.198 , 95% CIs = \[-0.634,0.143\], p = 0.215

=== Predicted probabilities and marginal effects
<predicted-probabilities-and-marginal-effects-1>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Because is on the logit scale we can back-transform it to the probability scale. To do this easily, we can use the `avg_predictions` function from `marginaleffects` package. Because we are interested in the zero-inflated part of the model we set the `type` argument to `zprob`.

```r
beta_model_0 %>%
  marginaleffects::avg_predictions(by = "Fluency_dummy", type="zprob") %>%
   select(Fluency_dummy, estimate) %>%
   tt(digits = 2)
```

#figure([
#[
#let nhead = 1;
#let nrow = 2;
#let ncol = 2;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 3, start: 0, end: 2, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 2, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 2, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Fluency_dummy], [estimate],
    ),

    // tinytable cell content after
[0], [0.023],
[1], [0.154],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-predict-zero>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The estimates provided in #link(<tbl-predict-zero>)[Table~17] are percentages of zeros in the model. There are fewer 0s in the fluent condition (2%) compared to the disfluent condition (15%).

We can also get the average marginal effect of Fluency like we did before:

```r
 beta_model_0 %>%
  marginaleffects::avg_comparisons(variables = "Fluency_dummy", type="zprob", comparison = "difference") %>%
   select(term, contrast, estimate) %>% 
  tt()
```

#figure([
#[
#let nhead = 1;
#let nrow = 1;
#let ncol = 3;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 2, start: 0, end: 3, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 3, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 3, stroke: 0.1em + black),

    table.header(
      repeat: true,
[term], [contrast], [estimate],
    ),

    // tinytable cell content after
[Fluency_dummy],
[mean(1) - mean(0)],
[0.1311189],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-marg-zib>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Interpreting the estimate in #link(<tbl-marg-zib>)[Table~18];, seeing lecture videos with a fluent instructor reduces the proportion of zeros by about 13%. Here we have evidence that participants were more likely to do more poorly after watching a disflueny lecture than a fluent lecture.

As a word of caution, the `marginaleffects` package has some issues with fitting models from `glmmTMB` and it has been recommended not to use it. Thus, we will not highlight it here. Please see this issue for more information: #link("https://github.com/vincentarelbundock/marginaleffects/issues/1064")

== Bayesian Implementation of zero-inflated beta
<bayesian-implementation-of-zero-inflated-beta>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Luckily, we can fit a zero-inflated model using `brms` and use the `marginaleffects` package to make inferences about our parameters of interest. Similar to our beta model we fit in `brms` we will use the `bf()` function to fit several models. We fit our $mu$ and $phi.alt$ parameters as well as our zero-inflated parameter ($alpha$; here labeled as `zi`). In `brms` we can use the zero\_inflated\_beta family argument.

#block[
```r
# fit zero-inflated beta in brms

zib_model <-   bf(
    Accuracy ~ Fluency_dummy,  # The mean of the 0-1 values, or mu
    phi ~ Fluency_dummy,  # The precision of the 0-1 values, or phi
    zi ~ Fluency_dummy,  # The zero-or-one-inflated part, or alpha
  family = zero_inflated_beta()
)
```

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Below we pass `zib_model` to the `brm` function.

#block[
```r
fit_zi <- brm(
  formula = zib_model,
  data = data_beta_0, 
  cores = 4,
  iter = 2000, 
  warmup = 1000, 
  seed = 1234, 
  backend = "cmdstanr",
  file = "model_beta_bayes_zib"
)
```

]
#figure([
#[
#let nhead = 1;
#let nrow = 6;
#let ncol = 9;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 7, start: 0, end: 9, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 9, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 9, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Parameter], [Component], [Mean], [CI], [CI_low], [CI_high], [pd], [Rhat], [ESS],
    ),

    // tinytable cell content after
[b_Intercept], [conditional], [-0.628], [0.95], [-0.844], [-0.413], [1], [0.999], [5919],
[b_phi_Intercept], [conditional], [ 2.0304], [0.95], [ 1.597], [ 2.425], [1], [1], [4743],
[b_Fluency_dummy1], [conditional], [-0.0334], [0.95], [-0.4], [ 0.335], [0.57], [1], [3715],
[b_phi_Fluency_dummy1], [conditional], [-0.8382], [0.95], [-1.399], [-0.283], [0.998], [1], [4604],
[b_zi_Intercept], [zero_inflated], [-3.8167], [0.95], [-6.22], [-2.224], [1], [1], [1630],
[b_zi_Fluency_dummy1], [zero_inflated], [ 2.1265], [0.95], [ 0.278], [ 4.595], [0.989], [1], [1793],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
position: top, 
[
Paramter estimates for zero-inflated beta model
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-brms-zib>


==== Predicted probabilities and marginal effects.
<predicted-probabilities-and-marginal-effects-2>
To get predicted probability from our model, we can set `dpar` argument to `zi` in `avg_predictions`. #link(<tbl-brms-zib-predict>)[Table~20] shows predicted probabilities of 0 for each level of fluency.

```r
fit_zi %>% 
 avg_predictions(variables = "Fluency_dummy", dpar="zi") %>%
  tt(digits=3)
```

#figure([
#[
#let nhead = 1;
#let nrow = 2;
#let ncol = 4;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 3, start: 0, end: 4, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 4, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 4, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Fluency_dummy], [estimate], [conf.low], [conf.high],
    ),

    // tinytable cell content after
[0], [0.0315], [0.00199], [0.0976],
[1], [0.1623], [0.07568], [0.2722],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-brms-zib-predict>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
In #link(<tbl-marg-zib-brms>)[Table~21];, we get the risk difference between each level of fluency. With a Bayesian implementation we get 95% credible intervals and we see the difference is significant.

#figure([
```r
fit_zi %>% 
  avg_comparisons(variables = "Fluency_dummy", dpar="zi", comparison = "difference")
```

#block[
```

          Term          Contrast Estimate  2.5 % 97.5 %
 Fluency_dummy mean(1) - mean(0)    0.131 0.0239  0.248

Columns: term, contrast, estimate, conf.low, conf.high, predicted_lo, predicted_hi, predicted, tmp_idx 
Type:  response 
```

]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-marg-zib-brms>


==== Plotting.
<plotting-2>
We can easily plot the zero-inflated part of the model using the `plot_predictions` function (see #link(<fig-brms-zib>)[Figure~9];)

#figure([
#box(image("beta_regression_draft_files/figure-typst/fig-brms-zib-1.svg"))
], caption: figure.caption(
position: top, 
[
Predicted zero-inflated probablities of fluency on final test accuracy
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-brms-zib>


== Zero-one inflated beta (ZOIB)
<zero-one-inflated-beta-zoib>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The ZIB model works well if you have 0s in your data, but not 1s. Sometimes it is theoretically useful to model zeros and ones. For example, this is important in visual analog scale data where there might be a prevalence of responses at the bounds (#link(<ref-vuorre2019>)[Vuorre, 2019];) or free-list task where individuals provide open responses to some question or topic that are then recoded to fall between 0-1 (#link(<ref-bendixen2023>)[Bendixen & Purzycki, 2023];), where 0 means item was not listed and 1 means item was listed first.

In our data, we have exactly one value equal to 1. While probably not significant to alter our findings, we can model ones with a special type of model called the zero-one inflated beta (ZOIB) model. Unfortunately, there is no frequentist implementation of the ZOIB model. Luckily, we can fit a Bayesian implementation of the ZOIB model in `brms`. In this model, we fit four parameters or sub-models. We fit separate models for the mean (\$\\mu\$) and the precision (\$\\phi\$) of the beta distribution; a zero-one inflation parameter (i.e.~the probability that an observation is either 0 or 1; $alpha$ ); and a 'conditional one inflation' parameter (i.e.~the probability that, given an observation is 0 or 1, the observation is 1; $gamma$). This specification captures the entire range of possible values while still being constrained between zero and one.

We use the `bf` function again to fit models for our four parameters. We use the native zero\_one\_inflated\_beta family to fit our model.

#block[
```r
# fit the zoib model

zoib_model <-   bf(
    Accuracy ~ Fluency_dummy,  # The mean of the 0-1 values, or mu
    phi ~ Fluency_dummy,  # The precision of the 0-1 values, or phi
    zoi ~ Fluency_dummy,  # The zero-or-one-inflated part, or alpha
    coi ~ Fluency_dummy,   # The one-inflated part, conditional on the 0s, or gamma
  family = zero_one_inflated_beta()
)
```

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
We then pass the `zoib_model` to our `brm` function. The summary of the output is in #link(<tbl-zoib>)[Table~22] .

#block[
```r
# run the zoib mode using brm 

fit_zoib <- brm(
  formula = zoib_model,
  data = fluency_data, 
  chains = 4, iter = 2000, warmup = 1000,
  cores = 4, seed = 1234, 
  backend = "cmdstanr",
  file = "model_beta_zoib_1" 
)
```

]
```r
zoib_model <- parameters::model_parameters(fit_zoib, "mean")

zoib_model %>%
 tt(digits=3)
```

#figure([
#[
#let nhead = 1;
#let nrow = 8;
#let ncol = 8;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 9, start: 0, end: 8, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 8, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 8, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Parameter], [Mean], [CI], [CI_low], [CI_high], [pd], [Rhat], [ESS],
    ),

    // tinytable cell content after
[b_Intercept         ], [-0.625], [0.95], [-0.832], [-0.418], [1    ], [1], [5843],
[b_phi_Intercept     ], [ 2.03 ], [0.95], [ 1.609], [ 2.417], [1    ], [1], [4319],
[b_zoi_Intercept     ], [-3.818], [0.95], [-6.16 ], [-2.224], [1    ], [1], [1782],
[b_coi_Intercept     ], [-1.856], [0.95], [-8.827], [ 2.874], [0.74 ], [1], [2202],
[b_Fluency_dummy1    ], [-0.202], [0.95], [-0.539], [ 0.14 ], [0.873], [1], [3541],
[b_phi_Fluency_dummy1], [-0.431], [0.95], [-1.02 ], [ 0.144], [0.931], [1], [4043],
[b_zoi_Fluency_dummy1], [ 2.27 ], [0.95], [ 0.445], [ 4.696], [0.993], [1], [1930],
[b_coi_Fluency_dummy1], [-0.224], [0.95], [-5.796], [ 7.326], [0.569], [1], [2348],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
position: top, 
[
Model summary for the zero-one inflated beta model
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-zoib>


=== Model parameters
<model-parameters-3>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The output for the model is pretty lengthy—we are estimating four parameters each with their own independent models. All the coefficients are on the logit scale, except $phi.alt$ , which is on the log scale. Thankfully drawing inferences for all these different parameters, plotting their distributions, and estimating their average marginal effects looks exactly the same—all the #strong[brms] and #strong[marginaleffects] functions we used work the same.

Should we show how to combine all the submodels and plot the overall effect here?

=== Plotting ZOIB
<plotting-zoib>
== Ordered beta regression
<ordered-beta-regression>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Looking at the output from the ZOIB model #link(<tbl-zoib>)[Table~22];, we can see how running a ZOIB model can become vastly complex and computational intensive with larger models as it is fitting submodels for each parameter. A special version of the ZOIB was recently developed called ordered beta regression (#link(<ref-kubinec2022>)[Kubinec, 2022];). The ordered beta regression model allows for the analysis of continuous data (between 0-1) and discrete outcomes (e.g., 0 or 1). In the simplest sense, the ordered beta regression model is a hybrid model that combines a beta model with ordinal logistic regression model. An in-depth explanation of ordinal regression is beyond the scope of this tutorial (but see (#link(<ref-bürkner2019>)[Bürkner & Vuorre, 2019];; #link(<ref-Fullerton2023>)[Fullerton & Anderson, 2021];)). At a basic level, ordinal regression models are useful for outcome variables that are categorical in nature and have some inherent ordering (e.g., Likert scale items). To preserve this ordering, ordinal models rely on the cumulative probability distribution. Within an ordinal regression model, going from one level or category to another is modeled with a single set of covariates that predicts cutpoints between each category. That is, each coefficient shows the effect of moving from one option to a higher option with #emph[k];-1 cutpoint parameters showing the boundaries or thresholds between the probabilities of these categories. Since there’s only one underlying process, there’s only one set of coefficients to work with (proportional odds assumption). In an ordered beta regression, three ordered categories are modeled: (1) exactly zero, (2) somewhere between zero and one, and (3) exactly one. In an ordered beta regression, (1) and (2) are modeled with cumulative logits, where one cutpoint is the the boundary between Exactly 0 and Between 0 and 1 and the other cutpoint is the boundary between #emph[Between 0 and 1] and #emph[Exactly 1.] Somewhere between 0-1 (3) is modeled as a beta regression with parameters reflecting the mean response on the logit scale. The ordered beta regression model has shown to be more efficient than some of the methods discussed herein and deserves special mention.

=== Frequentist implementation
<frequentist-implementation>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
We can run an ordered beta regression using the `glmmTMB` function and changing the family argument to `ordbeta`.

#figure([
#[
#let nhead = 1;
#let nrow = 3;
#let ncol = 11;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 4, start: 0, end: 11, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 11, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 11, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Parameter], [Coefficient], [SE], [CI], [CI_low], [CI_high], [z], [df_error], [p], [Component], [Effects],
    ),

    // tinytable cell content after
[(Intercept)], [\-0.58], [0.11], [0.95], [\-0.81], [\-0.3568], [\-5.1], [Inf], [0   ], [conditional], [fixed],
[Fluency_dummy1], [\-0.31], [0.16], [0.95], [\-0.63], [ 0.0031], [\-1.9], [Inf], [0.05], [conditional], [fixed],
[(Intercept)], [ 6.25], [], [0.95], [ 4.72], [ 8.2866], [], [], [], [dispersion], [fixed],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-ordbeta-glmm>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
If we take a look at the summary output in #link(<tbl-ordbeta-glmm>)[Table~23];, we can interpret the values similar to a beta regression.

==== Predicted probabilities and marginal effects.
<predicted-probabilities-and-marginal-effects-3>
Remember these values are on the logit scale so we can take the inverse and get predicted probabilities like we have done before. These values are in #link(<tbl-ordbeta-pred>)[Table~24];.

```r
# get the predicted probablities for each level of fluency 
avg_predictions(ord_fit, variables="Fluency_dummy") %>%
  select(-s.value)%>% 
  tt(digits = 2) %>%
    format_tt(j = "p", fn = scales::label_pvalue()) %>%
  format_tt(escape = TRUE) 
```

#figure([
#[
#let nhead = 1;
#let nrow = 2;
#let ncol = 7;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 3, start: 0, end: 7, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 7, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 7, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Fluency_dummy], [estimate], [std.error], [statistic], [p.value], [conf.low], [conf.high],
    ),

    // tinytable cell content after
[0], [0.36], [0.026], [14], [\<0.001], [0.31], [0.41],
[1], [0.29], [0.025], [12], [\<0.001], [0.24], [0.34],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-ordbeta-pred>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
We can get the risk difference as well. These values are in #link(<tbl-ordbeta-risk>)[Table~25];.

```r
# get risk difference 
avg_comparisons(ord_fit,variables="Fluency_dummy",  comparison= "difference") %>%
      select(-predicted_lo,-predicted_hi,-s.value, -predicted) %>% 
tt(digits = 2) %>%
    format_tt(j = "p", fn = scales::label_pvalue()) %>%
  format_tt(escape = TRUE)
```

#figure([
#[
#let nhead = 1;
#let nrow = 1;
#let ncol = 8;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 2, start: 0, end: 8, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 8, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 8, stroke: 0.1em + black),

    table.header(
      repeat: true,
[term], [contrast], [estimate], [std.error], [statistic], [p.value], [conf.low], [conf.high],
    ),

    // tinytable cell content after
[Fluency_dummy],
[mean(1) \- mean(0)],
[\-0.069],
[0.035],
[\-1.9],
[0.052],
[\-0.14],
[0.00045],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-ordbeta-risk>


== Bayesian implementation
<bayesian-implementation>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
To fit an ordered beta regression in a Bayesian context you can use `ordbetareg` (#link(<ref-ordbetareg>)[Kubinec, 2023];) package.

We first load in the `ordbetareg` package.

#block[
```r
# load ordbetareg package
library(ordbetareg)
```

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The `ordbetareg` package uses `brms` on the front-end and is straightforward to run. Instead of the `brm` function we use `ordbetareg`. It has similar arguments.

#block[
```r
# use ordbetareg to fit model
ord_fit_brms <- ordbetareg(Accuracy ~ Fluency_dummy,
                      data=fluency_data,
                      chains=4,
                      iter=2000,
                      backend="cmdstanr", 
                      file = "model_beta_ordbeta")
```

]
== Model parameters
<model-parameters-4>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
#link(<tbl-ordbeta-summ>)[Table~26] presents the model summary for our model.

```r
ord_fit_brms %>%
  model_parameters() %>%
  tt() %>%
  format_tt(digits=3)
```

#figure([
#[
#let nhead = 1;
#let nrow = 3;
#let ncol = 9;

  #let fill-array = ( 
    // tinytable cell fill after
  )
  #let style-array = ( 
    // tinytable cell style after
  )
  #show table.cell: it => {
    let tmp = it
    let data = style-array.find(data => data.x == it.x and data.y == it.y)
    if data != none {
      set text(data.color)
      set text(data.fontsize)
      if data.underline == true { tmp = underline(tmp) }
      if data.italic == true { tmp = emph(tmp) }
      if data.bold == true { tmp = strong(tmp) }
      if data.mono == true { tmp = math.mono(tmp) }
      if data.strikeout == true { tmp = strike(tmp) }
      tmp
    } else {
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    fill: (x, y) => {
      let data = fill-array.find(data => data.x == x and data.y == y)
      if data != none {
        data.fill
      }
    },

    // tinytable lines after
table.hline(y: 4, start: 0, end: 9, stroke: 0.1em + black),
table.hline(y: 1, start: 0, end: 9, stroke: 0.05em + black),
table.hline(y: 0, start: 0, end: 9, stroke: 0.1em + black),

    table.header(
      repeat: true,
[Parameter], [Component], [Median], [CI], [CI_low], [CI_high], [pd], [Rhat], [ESS],
    ),

    // tinytable cell content after
[b_Intercept], [conditional], [-0.579], [0.95], [-0.814], [-0.3534], [1], [1], [4107],
[b_Fluency_dummy1], [conditional], [-0.31], [0.95], [-0.625], [ 0.0113], [0.971], [1], [3996],
[phi], [distributional], [ 6.177], [0.95], [ 4.6], [ 8.1189], [1], [1], [4267],

    table.footer(
      repeat: false,
      // tinytable notes after
    ),

  ) // end table

  ]) // end align

]
], caption: figure.caption(
position: top, 
[
Model summary for ordered beta model
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-ordbeta-summ>


=== Ordered beta model fit
<ordered-beta-model-fit>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The best way to visualize model fit is to plot the full predictive distribution relative to the original outcome. Because ordered beta regression is a mixed discrete/continuous model, a separate plotting function, `pp_check_ordbetareg`, is included in the `ordbetareg` package that accurately handles the unique features of this distribution. This function returns a list with two plots, `discrete` and `continuous`, which can either be printed and plotted or further modified as `ggplot2` objects.

#block[
```r
plots <- pp_check_ordbeta(ord_fit_brms,
                          ndraws=100,
                          outcome_label="Final Test Accuracy")
```

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The discrete plot which is a bar graph, shows that the posterior distribution accurately captures the number of different types of responses (discrete or continuous) in the data.

```r
plots$discrete
```

#box(image("beta_regression_draft_files/figure-typst/unnamed-chunk-59-1.svg"))

#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
For the continuous plot shown as a density plot with one line per posterior draw, the model does a very good job at capturing the distribution.

```r
plots$continuous
```

#box(image("beta_regression_draft_files/figure-typst/unnamed-chunk-60-1.svg"))

#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Overall, it is clear from the posterior distribution plot that the ordered beta model fits the data well.

= Discussion and Conclusion
<discussion-and-conclusion>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The use of beta regression in psychology, and the social sciences in general, is rare. With this tutorial, we hope to change this. Beta regression models are an attractive alternative to models subsumed under the GLM, which imposes the unrealistic assumptions of normality, homoscadacidty, and requires the data to be unbounded. Beyond the GLM, there is a diverse array of different models that can be used depending on your outcome of interest.

Throughout this tutorial our main aim was to help guide researchers in running analyses with proportional or percentage outcomes using beta regression and some of it’s alternatives. In the current example we used real data from Wilford et al. (#link(<ref-wilford2020>)[2020];) and discussed how to fit these models in R, interpret model parameters, extract predicted probabilities and marginal effects, and visualize the results.

We showed that analyzing accuracy data using the traditional approach (i.e., #emph[t];-test) can lead to inaccurate inferences. In our example, we found a fluency effect for fluent instructors. However, when using a beta regression model, which take into account both the mean and precision, we saw that there was no effect. Fitting a zero-inflated beta model, we did find an effect of fluency; however, not on the mean component, but on the zero-inflated component. That is, those in the disfluent condition were more likely to do more poorly (have a higher probability of 0s). Here fluency does not affect the mean proportion correct, but instead affects the strutrual 0 part of the model. This has important theoretical implications and should be included in the discussion of fluency effects. We also showed how to fit data with zeros and ones but using the ZOIB and ordered beta models. We really only had one data.

Overall. This highlights the importance of modeling the data accurately. This also gives nice insights and more of a richness to the data than can be observed with traditional t-tests. If we just fit a t-test we would mistaken assume fluency effects the mean; however this is not the case. It affects the 0s in our model. here are a whole host of outcomes used in psychology that would be ideal for beta regression and its alternatives. Researchers now have some tools to analyze their data properly.

= References
<references>
#set par(first-line-indent: 0in, hanging-indent: 0.5in)
#block[
#block[
Arel-Bundock, V. (2024). #emph[Marginaleffects: Predictions, comparisons, slopes, marginal means, and hypothesis tests];. #link("https://CRAN.R-project.org/package=marginaleffects")

] <ref-marginaleffects>
#block[
Bartlett, M. S. (1936). The Square Root Transformation in Analysis of Variance. #emph[Journal of the Royal Statistical Society Series B: Statistical Methodology];, #emph[3];(1), 68–78. #link("https://doi.org/10.2307/2983678")

] <ref-bartlett1936>
#block[
Bendixen, T., & Purzycki, B. G. (2023). Cognitive and cultural models in psychological science: A tutorial on modeling free-list data as a dependent variable in Bayesian regression. #emph[Psychological Methods];. #link("https://doi.org/10.1037/met0000553")

] <ref-bendixen2023>
#block[
Brooks, M. E., Kristensen, K., van, K. J., Magnusson, A., Berg, C. W., Nielsen, A., Skaug, H. J., Maechler, M., & Bolker, B. M. (2017). #emph[glmmTMB balances speed and flexibility among packages for zero-inflated generalized linear mixed modeling];. #emph[9];. #link("https://doi.org/10.32614/RJ-2017-066")

] <ref-glmmTMB>
#block[
Bürkner, P.-C. (2017). #emph[Brms: An r package for bayesian multilevel models using stan];. #emph[80];. #link("https://doi.org/10.18637/jss.v080.i01")

] <ref-brms>
#block[
Bürkner, P.-C., & Vuorre, M. (2019). Ordinal Regression Models in Psychology: A Tutorial. #emph[Advances in Methods and Practices in Psychological Science];, #emph[2];(1), 77–101. #link("https://doi.org/10.1177/2515245918823199")

] <ref-bürkner2019>
#block[
Carpenter, S. K., Wilford, M. M., Kornell, N., & Mullaney, K. M. (2013). Appearances can be deceiving: instructor fluency increases perceptions of learning without increasing actual learning. #emph[Psychonomic Bulletin & Review];, #emph[20];(6), 1350–1356. #link("https://doi.org/10.3758/s13423-013-0442-z")

] <ref-carpenter2013>
#block[
Cribari-Neto, F., & Zeileis, A. (2010). #emph[Beta regression in r];. #emph[34];. #link("https://doi.org/10.18637/jss.v034.i02")

] <ref-betareg>
#block[
Ferrari, S., & Cribari-Neto, F. (2004). Beta Regression for Modelling Rates and Proportions. #emph[Journal of Applied Statistics];, #emph[31];(7), 799–815. #link("https://doi.org/10.1080/0266476042000214501")

] <ref-ferrari2004>
#block[
Fullerton, A. S., & Anderson, K. F. (2021). Ordered Regression Models: a Tutorial. #emph[Prevention Science];, #emph[24];(3), 431–443. #link("https://doi.org/10.1007/s11121-021-01302-y")

] <ref-Fullerton2023>
#block[
Heiss, A. (2021). #emph[A guide to modeling proportions with bayesian beta and zero-inflated beta regression models];. #link("http://dx.doi.org/10.59350/7p1a4-0tw75")

] <ref-heiss2021>
#block[
Kubinec, R. (2022). Ordered Beta Regression: A Parsimonious, Well-Fitting Model for Continuous Data with Lower and Upper Bounds. #emph[Political Analysis];, #emph[31];(4), 519–536. #link("https://doi.org/10.1017/pan.2022.20")

] <ref-kubinec2022>
#block[
Kubinec, R. (2023). #emph[Ordbetareg: Ordered beta regression models with ’brms’];. #link("https://CRAN.R-project.org/package=ordbetareg")

] <ref-ordbetareg>
#block[
Lüdecke, D. (2018). #emph[Ggeffects: Tidy data frames of marginal effects from regression models.] #emph[3];, 772. #link("https://doi.org/10.21105/joss.00772")

] <ref-ggeffects-2>
#block[
Lüdecke, D., Ben-Shachar, M. S., Patil, I., Wiernik, B. M., Bacher, E., Thériault, R., & Makowski, D. (2022). #emph[Easystats: Framework for easy statistical modeling, visualization, and reporting];. #link("https://easystats.github.io/easystats/")

] <ref-easystats>
#block[
Makowski, D., Ben-Shachar, M. S., Chen, S. H. A., & Lüdecke, D. (2019). Indices of effect existence and significance in the bayesian framework. #emph[Frontiers in Psychology];, #emph[10];. #link("https://doi.org/10.3389/fpsyg.2019.02767")

] <ref-makowski2019a>
#block[
Makowski, D., Ben-Shachar, M., & Lüdecke, D. (2019). bayestestR: Describing effects and their uncertainty, existence and significance within the bayesian framework. #emph[Journal of Open Source Software];, #emph[4];(40), 1541. #link("https://doi.org/10.21105/joss.01541")

] <ref-makowski2019>
#block[
Paolino, P. (2001). Maximum Likelihood Estimation of Models with Beta-Distributed Dependent Variables. #emph[Political Analysis];, #emph[9];(4), 325–346. #link("https://doi.org/10.1093/oxfordjournals.pan.a004873")

] <ref-paolino2001>
#block[
R Core Team. (2024). #emph[R: A language and environment for statistical computing];. R Foundation for Statistical Computing. #link("https://www.R-project.org/")

] <ref-R>
#block[
Rhodes, M. G. (2015). #emph[Judgments of learning] (J. Dunlosky & S. (Uma). K. Tauber, Eds.). Oxford University Press. #link("https://doi.org/10.1093/oxfordhb/9780199336746.013.4")

] <ref-rhodes2015>
#block[
Toftness, A. R., Carpenter, S. K., Geller, J., Lauber, S., Johnson, M., & Armstrong, P. I. (2017). Instructor fluency leads to higher confidence in learning, but not better learning. #emph[Metacognition and Learning];, #emph[13];(1), 1–14. #link("https://doi.org/10.1007/s11409-017-9175-0")

] <ref-toftness2017>
#block[
Vuorre, M. (2019, February 18). #emph[How to Analyze Visual Analog (Slider) Scale Data?] #link("https://vuorre.com/posts/2019-02-18-analyze-analog-scale-ratings-with-zero-one-inflated-beta-models")

] <ref-vuorre2019>
#block[
Wilford, M. M., Kurpad, N., Platt, M., & Weinstein-Jones, Y. (2020). Lecturer fluency can impact students’ judgments of learning and actual learning performance. #emph[Applied Cognitive Psychology];, #emph[34];(6), 1444–1456. #link("https://doi.org/10.1002/acp.3724")

] <ref-wilford2020>
#block[
Witherby, A. E., & Carpenter, S. K. (2022). The impact of lecture fluency and technology fluency on students’ online learning and evaluations of instructors. #emph[Journal of Applied Research in Memory and Cognition];, #emph[11];(4), 500–509. #link("https://doi.org/10.1037/mac0000003")

] <ref-witherby2022>
#block[
Yarkoni, T., & Westfall, J. (2017). Choosing Prediction Over Explanation in Psychology: Lessons From Machine Learning. #emph[Perspectives on Psychological Science];, #emph[12];(6), 1100–1122. #link("https://doi.org/10.1177/1745691617693393")

] <ref-yarkoni2017>
] <refs>
#set par(first-line-indent: 0.5in, hanging-indent: 0in)
#pagebreak(weak: true)
= Appendix
<appendix>
#counter(figure.where(kind: "quarto-float-fig")).update(0)
#counter(figure.where(kind: "quarto-float-tbl")).update(0)
#appendixcounter.step()
= Title for Appendix
<title-for-appendix>



