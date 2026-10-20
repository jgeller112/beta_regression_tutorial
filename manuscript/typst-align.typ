// Alignment overrides for apaquarto-typst output.

// Center tables. Wrapping in a full-width block is needed because the
// table's surrounding blocks otherwise shrink to the table's width.
#show table: it => block(width: 100%, align(center, it))

// apaquarto centers the contents of non-table floats (including code
// listings), which centers each line of code. Redefine Quarto's code block
// so that code is always left-aligned.
#let Skylighting(fill: none, number: false, start: 1, sourcelines) = {
  let blocks = []
  let lnum = start - 1
  let bgcolor = rgb("#f1f3f5")
  for ln in sourcelines {
    if number {
      lnum = lnum + 1
      blocks = blocks + box(width: if start + sourcelines.len() > 999 { 30pt } else { 24pt }, text(fill: rgb("#aaaaaa"), [ #lnum ]))
    }
    blocks = blocks + ln + EndLine()
  }
  align(left, block(fill: bgcolor, width: 100%, inset: 8pt, radius: 2pt, blocks))
}
