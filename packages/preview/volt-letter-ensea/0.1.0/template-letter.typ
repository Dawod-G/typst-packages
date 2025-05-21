// edited on 19/05/2025

// ============================
// CONFIGURATION
// ============================

#let letter(
  authors: none,
  position: none,
  date: datetime.today(),
  body,
) = {
  // Check if all mandatory variables are defined.
  if authors == none {
    panic(
      "The `authors` variable must be defined. It should be a list of strings representing the authors of the document.",
    )
  }

  if position == none {
    panic("The `position` variable must be defined. It should be a string.")
  }

  set document(author: authors)

  set page(paper: "a4", margin: auto, number-align: center)

  // if "weak: true", the page break is skipped if the current page is already empty
  set pagebreak(weak: true)

  set text(font: "New Computer Modern", size: 12pt, lang: "fr", region: "fr")
  /* for English: lang: 'en' and region: 'us'
  For other languages/regions, refer to this page:
  lang: https://en.wikipedia.org/wiki/ISO_639
  region: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2 */

  show heading : set text(hyphenate: false)

  // Config. of the spacing after headings
  show heading.where(level: 1): set block(spacing: 1em)

  set list(indent: 15pt, marker: [--])

  show figure.where(kind: image): set figure(supplement: "Figure")

  // Configure the figure caption alignment:
  // if figure caption has more than one line,
  // it makes it left-aligned
  show figure.caption: it => {
    layout(size => [
      #let text-size = measure(it.supplement + it.separator + it.body)
      #let my-align
      #if text-size.width < size.width {
        my-align = center
      } else {
        my-align = left
      }
      #align(my-align, it)
    ])
  }

  // Configure the raw block properties
  show raw.where(block: true): set par(justify: false)

  // From the INSA Typst Template by SkytAsul:
  // https://github.com/SkytAsul/INSA-Typst-Template
  show raw.line: it => if it.count > 1 {
    text(fill: luma(150), str(it.number)) + h(2em) + it.body
  } else { it }

  // Display links in blue
  show link: set text(fill: blue.darken(40%))

  set par(justify: true)

  // Page configuration
  set page(
    margin: (top: 80pt),
    header-ascent: 10pt,
    header: context [
      #stack(
        dir: ltr,

        align(left + horizon, image("assets/logo-ENSEA.jpg", height: 14mm)),

        align(right + horizon)[
          #text(size: 10pt)[#box(width: 86%)[#(
                authors.join(", ", last: " et ")
              )
              #linebreak()
              #position
              #linebreak()
              // From the INSA Typst Template by SkytAsul:
              // https://github.com/SkytAsul/INSA-Typst-Template
              #if type(date) == datetime [
                #date.display("[day]/[month]/[year]")
              ] else [
                #date
              ]
            ]]],
      )
      #box(width: 100%, height: 1pt, fill: black)
    ],

    footer: context [
      #if counter(page).final() != (1,) {
        align(center + top)[#text(size: 10pt)[#counter(page).display(
              "1/1",
              both: true,
            )]]
      }
    ],
  )

  body
}
