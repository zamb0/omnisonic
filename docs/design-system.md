# Omnisonic — Design System

Fonte di verità per tema, componenti e impaginazione. Il codice vive in
`lib/core/design_system/` (barrel `design_system.dart`); questo documento dice
**quale token usare e perché**. Se un componente ha bisogno di un valore che qui
non c'è, si aggiunge il token qui e in codice — mai un numero letterale nella
feature (lo verifica `test/core/design_system/token_guardrail_test.dart`).

Metodo: skill *ui-ux-pro-max* (stile `liquid-glass`, prodotto *Music
Streaming*, stack `flutter`) applicata alla direzione "liquid glass" già
presente nell'app, non sostituita. Il generatore suggeriva Inter + accento
verde OLED: scartato, perché avrebbe buttato via un'identità già riconoscibile
(Gabarito/Manrope/JetBrains Mono, vetro tinto dalla copertina).

---

## 1. Principi

1. **Il contenuto ha il colore, il chrome è vetro.** Le copertine e la tinta
   che ne deriva (`ArtTintBackground`) sono l'unica fonte di colore "forte".
   Sidebar, barre e pannelli sono vetro neutro: non competono con l'artwork.
2. **Inchiostro + un accento.** Due soli colori d'enfasi, con ruoli separati:
   - **Ink** (`onSurface`): l'azione primaria (Play, Salva, Aggiungi) e il
     "sei qui" della navigazione. È il bottone bianco su scuro / nero su chiaro.
   - **Accent** (`primary`, pervinca/indaco): solo **stato vivo** — traccia in
     riproduzione, avanzamento, focus da tastiera, toggle attivi, selezione.
   Un elemento non è mai sia ink che accent. Mai accent su un'azione statica.
3. **La gerarchia sta nella tipografia, non nella decorazione.** Niente chip
   d'icona accanto ai titoli, niente bordi colorati per dire "importante".
4. **Un ritmo.** Griglia a 4 pt; ogni distanza è un token.
5. **Raggi annidati.** Un contenitore ha raggio ≥ di quello che contiene;
   dentro un pannello da 20 con padding 16 si usano tile da 12.
6. **Lo stato non è mai solo colore.** Icona + etichetta (chip di stato,
   feedback), `Semantics` su ogni controllo icon-only.

---

## 2. Colore

### 2.1 Superfici (strato per strato)

| Livello | Ruolo | Scuro | Chiaro | Token |
|---|---|---|---|---|
| L0 | Tela + tinta copertina | `#0D0E10` | `#EFEDEA` | `scheme.surface`, `ArtTintBackground` |
| L1 | Pannello vetro (sidebar, rail statistiche, card) | bianco 6→4 % + blur 24 | bianco 66→38 % + blur 24 | `GlassSurface(intensity: card)` |
| L2 | Chrome flottante (player bar, bottom nav) | bianco 9→6 % + blur 28 | bianco 72→46 % + blur 28 | `GlassSurface(intensity: pill)` / `GlassPanel` |
| L3 | Overlay (dialog, sheet, menu) | `#1D1E22` opaco | `#F7F5F2` opaco | `scheme.surfaceContainerHigh` |
| — | Pozzetto dentro il vetro (input, stat tile, righe server) | bianco 6 % | bianco 55 % | `surfaces.well` |
| — | Segnaposto copertina | `#1D1E22` | `#DEDAD4` | `surfaces.placeholder` |

Gli overlay sono **opachi**: un dialog sfocato sopra contenuto sfocato è
illeggibile e costoso. Si distinguono per raggio 24, filo sottile e ombra.

Scala dei contenitori (sostituisce i default Material che collassavano tutti
su `surface`, per cui input e segnaposto sparivano sulla tela scura):

| Token | Scuro | Chiaro |
|---|---|---|
| `surfaceContainerLowest` | `#08090A` | `#FFFFFF` |
| `surfaceContainerLow` | `#121316` | `#F6F4F1` |
| `surfaceContainer` | `#17181B` | `#EAE7E3` |
| `surfaceContainerHigh` | `#1D1E22` | `#F7F5F2` |
| `surfaceContainerHighest` | `#24252A` | `#DEDAD4` |

### 2.2 Testo e linee

| Token | Scuro | Chiaro | Contrasto su tela / su vetro |
|---|---|---|---|
| `onSurface` (testo primario, ink) | `#F4F2EF` | `#141414` | 17.3 / 13.9 · 15.8 / 17.4 |
| `onSurfaceVariant` (secondario) | `#A8A49E` | `#5A554E` | 7.8 / 6.3 · 6.3 / 7.0 |
| `outline` (bordo input, ≥ 3:1) | `#6A665F` | `#8A847B` | ≥ 3:1 |
| `outlineVariant` / `surfaces.hairline` (divisori) | bianco 10 % | nero 8 % | decorativo |

Neutri **caldi** in entrambi i temi: i grigi freddi Tailwind (`#4B5563`)
stonavano sulla tela greige.

### 2.3 Accento e semantici

| Token | Scuro | Chiaro | Uso |
|---|---|---|---|
| `primary` (accent) | `#A5A8FF` | `#4F46E5` | stato vivo, focus, progress |
| `onPrimary` | `#15163A` | `#FFFFFF` | testo su accent (8.0 / 6.3) |
| `error` | `#FF6B6B` | `#DC2626` | errori, distruttivo |
| success / warning / info | vividi su scuro, `*Accessible` su chiaro | | solo via `ServerStatusVisuals`, `InlineBanner`, `showFeedback` |
| Server dot | `OmnisonicColors.serverHueSwatches` | | identità della sorgente, mai stato |

### 2.4 Su copertina

Tutto ciò che sta sopra un'immagine usa `OmnisonicColors.scrim` /
`scrimStrong` + `onScrim` / `onScrimMuted`, in entrambi i temi.

---

## 3. Tipografia

Tre famiglie, tre voci. Nessun `letterSpacing` "Material" da 0.25–0.5 sul
testo corrente: con Manrope dava un'aria da form gestionale.

| Ruolo | Token | Famiglia | Size / peso / tracking | Dove |
|---|---|---|---|---|
| Titolo pagina | `pageTitle` | Gabarito | 40 / 800 / −0.8 | header di ogni schermata (≥ 480 px) |
| Titolo sezione | `sectionTitle` | Gabarito | 28 / 800 / −0.5 | sezioni Home, titolo pagina compatto |
| Titolo sezione compatto | `sectionTitleSmall` | Gabarito | 22 / 800 / −0.2 | sezioni su telefono, rail |
| Titolo overlay | `overlayTitle` | Gabarito | 20 / 700 / −0.2 | dialog, sheet |
| Titolo di gruppo | `groupTitle` | Gabarito | 17 / 700 / 0 | "Tracks", "Details", sezioni Settings |
| Riga primaria | `titleMedium` | Manrope | 15 / 600 | ListTile, righe |
| Corpo | `bodyMedium` | Manrope | 14 / 400 / 0 | testo corrente |
| Corpo piccolo | `bodySmall` | Manrope | 12 / 500 / 0 | sottotitoli, artista |
| Bottone | `button` | Gabarito | 14 / 700 / 0 | tutti i bottoni Material e vetro |
| Etichetta nav | `navLabel` | Gabarito | 13.5 / 600 | sidebar, tab |
| Card | `cardTitle` / `cardSubtitle` / `cardMeta` | Manrope / Manrope / Mono | 13·12·11 | MediaCard |
| Dato tecnico | `technical` / `technicalSmall` | JetBrains Mono | 12 / 11, 600, tnum | bitrate, conteggi, durate |
| Eyebrow | `eyebrow` | JetBrains Mono | 11 / 600 / +0.8, MAIUSCOLO | etichette di gruppo |

Pavimento: 11 px per etichette mono, 12 px per testo informativo.

---

## 4. Spaziatura (4 pt)

| Token | px | Uso tipico |
|---|---|---|
| `xxs` | 2 | titolo ↔ sottotitolo in una riga |
| `xs` | 4 | icona ↔ testo stretto |
| `sm` | 8 | gap fra elementi di un controllo |
| `ms` | 12 | gap in tile, header sezione → contenuto |
| `md` | 16 | padding pannello, gutter telefono, gap griglia |
| `ml` | 20 | padding pannello grande |
| `lg` | 24 | gutter tablet/desktop, padding overlay |
| `xl` | 32 | stacco fra sezioni (compatto) |
| `xxl` | 40 | stacco fra sezioni (largo) |
| `xxxl` | 48 | respiro sopra empty state |

---

## 5. Raggi

| Token | px | Uso |
|---|---|---|
| `xs` | 4 | barre di progresso, mini-thumbnail < 48 |
| `sm` | 8 | thumbnail 48–96, badge su copertina |
| `md` / `tile` / `control` | 12 | tile, input, voci di menu, nav item |
| `art` | 14 | copertine ≥ 96 |
| `xl` / `panel` | 20 | pannelli vetro, player bar |
| `xxl` / `overlay` | 24 | dialog, sheet, card "Riprendi" |
| `full` | ∞ | bottoni, chip, campo di ricerca, avatar, artista |

**Bottoni e chip sono sempre a stadio** (`full`); i contenitori mai.

---

## 6. Elevazione e materiali

Niente `elevation` Material: profondità = strato vetro + ombra dedicata.

| Token | Uso |
|---|---|
| `OmnisonicShadows.art` / `artCompact` | copertine che galleggiano |
| ombra di `GlassSurface` (card/pill) | pannelli L1/L2 |
| `OmnisonicShadows.overlay` | dialog, sheet, menu (L3) |

---

## 7. Movimento

`AnimationManager`: 150 ms stati, 200 ms swap, 300 ms spostamenti, 600 ms
tinta. Sempre passando da `AnimationUtils.adjustedDuration` (reduce motion →
0). Hover: scala copertina 1.03 + overlay in dissolvenza; mai spostamenti di
layout al press.

---

## 8. Iconografia

Solo `OmnisonicIcons` (famiglia *rounded*, *outlined* per lo stato inattivo).
Taglie: `inline` 14 · `sm` 16 · `smd` 20 (toolbar, azioni riga) · `md` 24
(nav, transport) · `lg` 32 (play grande). Target ≥ 44 × 44 sempre.

---

## 9. Componenti

| Componente | Spec |
|---|---|
| **FilledButton** (primario) | ink su tela: `onSurface` fill, `surface` testo; stadio; h 44; `button` |
| **FilledButton.tonal** (secondario) | `surfaces.well` + filo; testo `onSurface` |
| **OutlinedButton** | filo `outline`; testo `onSurface` |
| **TextButton** (terziario, "See all") | testo `onSurfaceVariant` → `onSurface` in hover; stadio |
| **Distruttivo** | `FilledButton` con `error` / `onError` |
| **IconButton** | 44 × 44, icona `smd` 20, hover `onSurface` 8 % |
| **GlassInkButton** | bottone vetro (search, "Sync now"), stadio |
| **Input** | pozzetto `well`, raggio 12, filo `hairline` → `primary` 2 px al focus |
| **SearchField** | pozzetto a stadio, icona 20, h 48 |
| **Chip / Segmented** | stadio, `well`, `labelMedium`; selezionato = toggle acceso → tinta accent 14–22 % + bordo accent, testo resta `onSurface` |
| **Nav item** (sidebar, rail, bottom bar, account) | selezionato = pillola ink (testo `surface`), uguale ovunque |
| **SectionHeader** | `large` (Home) · `medium` (`groupTitle`) · `small` (eyebrow) + azione TextButton |
| **PageHeader** | titolo a `gutter`, allineato al contenuto; azioni IconButton |
| **MediaCard** | copertina `art` + ombra, testo 8 sotto, overlay vetro scuro al hover |
| **TrackRow** | h ≥ 56, thumb 48 (`sm`), titolo `titleSmall`, mono per durata; corrente = accent |
| **Dialog / Sheet / Menu** | L3, raggio 24/24/12, filo, `overlayTitle` |
| **Snackbar** | inverse surface, flottante, raggio 12, icona per tipo |
| **Empty / error state** | icona in disco `well` 72, `groupTitle`, corpo, azione FilledButton |

---

## 10. Impaginazione

### 10.1 Due misure: chrome e gutter

- **`chromeInset` = 12**: distanza del chrome flottante (sidebar, player bar,
  bottom nav) dal bordo finestra e fra pannelli di chrome.
- **`gutter`**: margine orizzontale del contenuto pagina. Lo pubblica la shell
  con `PageGutter`, così titolo, sezioni, griglie, caroselli e top bar hanno
  **lo stesso bordo sinistro**:
  - bottom bar (telefono): 16 (20 da 480 px)
  - sidebar (rail o estesa): 24 dal bordo della sidebar

Prima: Home usava 4 px su telefono, Library 16–32, l'header 16 fisso, la
player bar toccava la sidebar (0 px).

### 10.2 Ritmo verticale

| Distanza | Valore |
|---|---|
| top pagina → titolo | `sm` 8 (telefono) / `md` 16 |
| titolo pagina → primo blocco | `ms` 12 |
| fra sezioni | `xl` 32 (compatto) / `xxl` 40 (largo) |
| header sezione → contenuto | `ms` 12 |
| fondo pagina | `xxl` 40 |

### 10.3 Larghezze

- Griglie: `MediaGridPreset` (140–200 px per cella, gap 16).
- Caroselli: padding orizzontale = `gutter`; il primo elemento si allinea al
  titolo, lo scorrimento arriva al bordo finestra (niente taglio nel margine).
- Contenuto da leggere (Settings, dettagli server, form): max **720 px**.
- Dialog: max 440 px.

### 10.4 Griglia dei breakpoint

`ResponsiveBreakpoints`: 480 / 768 / 1024 / 1440. La shell sceglie il chrome
dalle proprie constraint; le pagine chiedono a `ShellLayout` / `PageGutter`,
non a `MediaQuery`.
