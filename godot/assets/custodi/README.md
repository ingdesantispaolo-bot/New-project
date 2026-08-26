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
