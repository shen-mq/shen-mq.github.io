#import "@preview/tufted:0.1.1"

#let template = tufted.tufted-web.with(
  header-links: (
    "/": "Home",
    "/blog/": "Blog",
    "/notes/": "Notes",
  ),
  title: "Tufted",
)
