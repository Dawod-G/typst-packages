/// The Frappé flavor and palette.
///
/// ==== Example
/// ```example
/// #let flavor = flavors.frappe
/// Selected flavor: #flavor.name #flavor.emoji
/// ```
///
/// -> flavor
#let frappe = (
  name: "Frappé",
  identifier: "frappe",
  emoji: "🪴",
  order: 1,
  dark: true,
  light: false,
  colors: (
    rosewater: (
      name: "Rosewater",
      order: 0,
      hex: "#f2d5cf",
      rgb: rgb(242, 213, 207),
      accent: true,
    ),
    flamingo: (
      name: "Flamingo",
      order: 1,
      hex: "#eebebe",
      rgb: rgb(238, 190, 190),
      accent: true,
    ),
    pink: (
      name: "Pink",
      order: 2,
      hex: "#f4b8e4",
      rgb: rgb(244, 184, 228),
      accent: true,
    ),
    mauve: (
      name: "Mauve",
      order: 3,
      hex: "#ca9ee6",
      rgb: rgb(202, 158, 230),
      accent: true,
    ),
    red: (
      name: "Red",
      order: 4,
      hex: "#e78284",
      rgb: rgb(231, 130, 132),
      accent: true,
    ),
    maroon: (
      name: "Maroon",
      order: 5,
      hex: "#ea999c",
      rgb: rgb(234, 153, 156),
      accent: true,
    ),
    peach: (
      name: "Peach",
      order: 6,
      hex: "#ef9f76",
      rgb: rgb(239, 159, 118),
      accent: true,
    ),
    yellow: (
      name: "Yellow",
      order: 7,
      hex: "#e5c890",
      rgb: rgb(229, 200, 144),
      accent: true,
    ),
    green: (
      name: "Green",
      order: 8,
      hex: "#a6d189",
      rgb: rgb(166, 209, 137),
      accent: true,
    ),
    teal: (
      name: "Teal",
      order: 9,
      hex: "#81c8be",
      rgb: rgb(129, 200, 190),
      accent: true,
    ),
    sky: (
      name: "Sky",
      order: 10,
      hex: "#99d1db",
      rgb: rgb(153, 209, 219),
      accent: true,
    ),
    sapphire: (
      name: "Sapphire",
      order: 11,
      hex: "#85c1dc",
      rgb: rgb(133, 193, 220),
      accent: true,
    ),
    blue: (
      name: "Blue",
      order: 12,
      hex: "#8caaee",
      rgb: rgb(140, 170, 238),
      accent: true,
    ),
    lavender: (
      name: "Lavender",
      order: 13,
      hex: "#babbf1",
      rgb: rgb(186, 187, 241),
      accent: true,
    ),
    text: (
      name: "Text",
      order: 14,
      hex: "#c6d0f5",
      rgb: rgb(198, 208, 245),
      accent: false,
    ),
    subtext1: (
      name: "Subtext 1",
      order: 15,
      hex: "#b5bfe2",
      rgb: rgb(181, 191, 226),
      accent: false,
    ),
    subtext0: (
      name: "Subtext 0",
      order: 16,
      hex: "#a5adce",
      rgb: rgb(165, 173, 206),
      accent: false,
    ),
    overlay2: (
      name: "Overlay 2",
      order: 17,
      hex: "#949cbb",
      rgb: rgb(148, 156, 187),
      accent: false,
    ),
    overlay1: (
      name: "Overlay 1",
      order: 18,
      hex: "#838ba7",
      rgb: rgb(131, 139, 167),
      accent: false,
    ),
    overlay0: (
      name: "Overlay 0",
      order: 19,
      hex: "#737994",
      rgb: rgb(115, 121, 148),
      accent: false,
    ),
    surface2: (
      name: "Surface 2",
      order: 20,
      hex: "#626880",
      rgb: rgb(98, 104, 128),
      accent: false,
    ),
    surface1: (
      name: "Surface 1",
      order: 21,
      hex: "#51576d",
      rgb: rgb(81, 87, 109),
      accent: false,
    ),
    surface0: (
      name: "Surface 0",
      order: 22,
      hex: "#414559",
      rgb: rgb(65, 69, 89),
      accent: false,
    ),
    base: (
      name: "Base",
      order: 23,
      hex: "#303446",
      rgb: rgb(48, 52, 70),
      accent: false,
    ),
    mantle: (
      name: "Mantle",
      order: 24,
      hex: "#292c3c",
      rgb: rgb(41, 44, 60),
      accent: false,
    ),
    crust: (
      name: "Crust",
      order: 25,
      hex: "#232634",
      rgb: rgb(35, 38, 52),
      accent: false,
    ),
  ),
)
