# Radura Accademia — asset pass 1

Questi SVG sono il primo passaggio visuale del vertical slice, non il set
artistico definitivo. Sono volutamente vettoriali e leggeri per permettere
iterazioni rapide e un export Web piccolo.

Il passaggio artistico attuale riusa anche gli sprite Phaser già approvati:

| Asset | Uso Godot |
| --- | --- |
| `outdoor-world-sheet.png` | alberi, cespugli, rocce, cristalli, rovine, ponti, laghetti, panchine, lampade e beacon |
| `eli-robot-girl-sheet.png` | sprite principale di Eli nel mondo esterno |

Sono letti come atlas region in `scripts/visual_factory.gd`; la grafica
procedurale resta come fallback per i tipi non ancora coperti e per gli effetti
dinamici (ombre, glow, particelle e giorno/notte).

| Asset | Uso |
| --- | --- |
| `academy-ground.svg` | texture di base del chunk |
| `academy-tree.svg` | ostacoli alberati |
| `academy-rock.svg` | ostacoli solidi rocciosi |
| `academy-treasure.svg` | tesori interagibili |
| `academy-encounter.svg` | incontri didattici |
| `academy-portal.svg` | portale di uscita |

Il codice dipende solo dal percorso `res://assets/...`; i file potranno quindi
essere sostituiti con export Aseprite/Illustrator mantenendo invariati i
contratti del runtime.
