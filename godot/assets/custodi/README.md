# Custodi illustrati

Undici compagni generativi 384×384 con alpha reale, uno per ogni `kind` del
catalogo cosmetico: dog, cat, rabbit, spark, comet, orbit, satellite, prisma,
luma, guardiano e codex.

Modalità: ImageGen integrato, una chiamata distinta per Custode. Prompt comune:

> Friendly magical companion sprite for Eli Quest, premium hand-painted 2D
> game art with painterly pixel-art-adjacent finish, elevated three-quarter
> camera, compact child-friendly fantasy/science-fantasy design, crisp opaque
> silhouette readable at 48–64 pixels, one centered full body, perfectly flat
> #ff00ff chroma-key background, no transparent materials, smoke, particles,
> text, watermark, extra pose, shadow or scenery.

La livrea dinamica resta nel bagliore Godot e applica soltanto una tinta leggera
al dipinto. Se un asset manca, `OutdoorVisualFactory.build_pet()` conserva il
vecchio fallback procedurale.

## Animazione runtime

Le illustrazioni restano tavole singole: `pet_companion.gd` le anima con
squash-and-stretch, inclinazioni e piccoli oggetti di scena vettoriali. Tutte le
16 combinelle hanno una posa distinta (coda, starnuto, ombra, eco, foglia,
inchino e le altre), con una variante statica dedicata quando e' attiva la
riduzione del movimento. La copertura catalogo -> posa e' verificata da
`pet_advanced_audit.gd`; la tavola visiva si rigenera con
`pet_antics_render_probe.gd`.

## Ritratti emotivi

Ogni specie ha anche le tavole `*-beato-v2.png` e `*-stupito-v2.png`, generate a
partire dal proprio asset e usate per carezza e meraviglia narrativa. Non sono
volti generici: cane, gatto,
coniglio, creature cristalline e robot con un occhio conservano identita',
materiali e accessori. Il widget ritaglia il primo piano dalla tavola corretta,
mentre specie e indole decidono se l'affetto e' esuberante, dolce, luminoso o
composto. Gli errori scolastici restano sempre incoraggianti.

Le altre espressioni nuove — `coraggioso`, `sollevato` e `assonnato` — mantengono
la tavola della specie equipaggiata e cambiano posa, ritmo e segni animati. In
questo modo la storia modifica l'emozione senza sostituire il personaggio.
