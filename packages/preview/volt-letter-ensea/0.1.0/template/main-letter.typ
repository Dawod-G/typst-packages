#import "@preview/volt-letter-ensea:0.1.0": *

// ============================
// VARIABLES TO MODIFY
// ============================

#show: letter.with(
  // Name(s) of the document author(s)
  authors: (
    "Jean DUPONT",
  ),

  // Position or role of the author(s)
  position: [1Gx TDy TPz],

  // Date of the document
  date: datetime.today(), // or "DD/MM/YYYY"
)

// ============================
// START HERE
// DELETE THE LINES BELOW THIS COMMENT
// ============================

= Titre de niveau 1
#lorem(70)

== Titre de niveau 2
#lorem(50)

#figure(image("media/logo-ENSEA.jpg", width: 25%), caption: [Logo de l'ENSEA])

=== Titre de niveau 3
#lorem(35)

```java
// HelloWorld.java
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
```

// Insert a page break
#pagebreak()

= Conclusion
#lorem(350)
