# Omnisonic — Design System

> **v2 · "Aurora Glass"** — novembre 2026. Questo documento descrive il
> sistema **target**: i token qui sotto sostituiscono quelli della v1 ("liquid
> glass" monocromo) e vengono portati nel codice dall'epica
> #90 (sotto-task D1–D12 = #78–#89). Finché una sotto-issue non è chiusa, il codice può ancora usare
> il valore v1; la tabella in §12 dice cosa cambia e dove.

Fonte di verità per tema, componenti e impaginazione. Il codice vive in
`lib/core/design_system/` (barrel `design_system.dart`); questo documento dice
**quale token usare e perché**. Se un componente ha bisogno di un valore che qui
non c'è, si aggiunge il token qui e in codice — mai un numero letterale nella
feature (lo verifica `test/core/design_system/token_guardrail_test.dart`).

Metodo: skill *ui-ux-pro-max* (stili `liquid-glass` + `aurora-ui`, prodotto
*Music Streaming*, stack `flutter`). Il generatore proponeva Righteous/Poppins
e un verde "play" alla Spotify: scartati entrambi. Le tre famiglie restano
(Gabarito/Manrope/JetBrains Mono, sono già l'identità); cambia il colore.

**Perché la v2.** La v1 era corretta ma spenta: tela greige/near-black, un
pervinca usato col contagocce, primario bianco. Su schermate senza copertine
(Settings, server, empty state, Library in lista) l'app non aveva alcun
carattere. La v2 dà al brand una **firma** riconoscibile — il gradiente
Aurora — e una tela con temperatura, senza togliere il palco alle copertine.

---

## 1. Principi

1. **Il contenuto ha il colore, il chrome è vetro.** Le copertine e la tinta
   che ne deriva (`ArtTintBackground`) restano la fonte di colore principale.
   Il vetro è neutro ma prende la temperatura della tela (midnight/pearl).
2. **Tre voci d'enfasi, ruoli separati.**
   - **Aurora** (gradiente violet → magenta → coral): la *firma*. Solo per il
     Play principale di una schermata, il marchio, l'avanzamento del brano in
     riproduzione e lo sfondo di riserva quando non c'è copertina.
     **Al massimo un elemento Aurora pieno per schermata.**
   - **Ink** (`onSurface`): le azioni primarie statiche (Salva, Aggiungi,
     Connetti) e il testo. Bottone bianco su scuro / quasi-nero su chiaro.
   - **Accent** (`primary`, violetto elettrico): **stato vivo** — brano in
     riproduzione, focus, toggle attivi, selezione, link.
   Più due colori di ruolo, mai decorativi: **Heat** (coral, preferiti/love) e
   **Aqua** (`tertiary`, info, download, offline).
3. **La gerarchia sta nella tipografia, non nella decorazione.** Niente chip
   d'icona accanto ai titoli, niente bordi colorati per dire "importante".
4. **Un ritmo.** Griglia a 4 pt; ogni distanza è un token.
5. **Raggi annidati.** Un contenitore ha raggio ≥ di quello che contiene;
   dentro un pannello da 20 con padding 16 si usano tile da 12.
6. **Lo stato non è mai solo colore.** Icona + etichetta, `Semantics` su ogni
   controllo icon-only, equalizer animato *e* icona per "in riproduzione".
7. **Il movimento risponde, non decora.** Ogni animazione segue un input o un
   cambio di stato; niente loop decorativi tranne l'equalizer del brano vivo e
   la deriva lenta dell'Aurora di riserva (entrambi spenti con reduce motion).

---

## 2. Colore

Tutte le coppie testo/sfondo dichiarate qui sono state misurate (WCAG 2.x).
Valori come `x.x:1` sono sul canvas del tema.

### 2.1 Tela e superfici (strato per strato)

La tela non è più neutra: **Midnight** (nero-violaceo) in scuro, **Pearl**
(bianco lilla appena caldo) in chiaro. La scala dei contenitori sale nello
stesso tono, così vetro, pozzetti e overlay sembrano dello stesso materiale.

| Livello | Ruolo | Scuro | Chiaro | Token |
|---|---|---|---|---|
| L0 | Tela + tinta copertina | `#0B0A12` | `#F6F4FA` | `scheme.surface`, `ArtTintBackground` |
| L1 | Pannello vetro (sidebar, rail, card) | bianco 6→4 % + blur 24 + sheen | bianco 66→40 % + blur 24 | `GlassSurface(intensity: card)` |
| L2 | Chrome flottante (player bar, bottom nav) | bianco 10→6 % + blur 28 + bordo luce | bianco 74→48 % + blur 28 | `GlassSurface(intensity: pill)` |
| L3 | Overlay (dialog, sheet, menu) | `#1C1A29` opaco | `#FFFFFF` opaco | `scheme.surfaceContainerHigh` |
| — | Pozzetto (input, stat tile, righe server) | bianco 6 % | `#2A1F5C` 5 % | `surfaces.well` |
| — | Pozzetto hover / selezionato | bianco 10 % | `#2A1F5C` 9 % | `surfaces.wellHover` |
| — | Segnaposto copertina | gradiente `#1C1A29 → #262338` | gradiente `#E9E5F1 → #DED8EA` | `surfaces.placeholder` + hue del seed |

Gli overlay restano **opachi**: si distinguono per raggio 24, filo e ombra.

| Token | Scuro | Chiaro |
|---|---|---|
| `surfaceContainerLowest` | `#07060C` | `#FFFFFF` |
| `surfaceContainerLow` | `#100F19` | `#FBFAFD` |
| `surfaceContainer` | `#15141F` | `#EFECF5` |
| `surfaceContainerHigh` | `#1C1A29` | `#FFFFFF` |
| `surfaceContainerHighest` | `#262338` | `#E9E5F1` |

**Bordo luce (L2).** Il chrome flottante in scuro prende un filo superiore
`white 14 %` → `white 0 %` (gradiente verticale sul bordo): dà lo spessore del
vetro senza ombra pesante. In chiaro il filo è `white 90 %`.

### 2.2 Testo e linee

| Token | Scuro | Chiaro | Contrasto (scuro · chiaro) |
|---|---|---|---|
| `onSurface` (testo, ink) | `#F3F1F8` | `#17141F` | 17.6 · 16.6 |
| `onSurfaceVariant` (secondario) | `#A9A4BC` | `#5C5670` | 8.2 · 6.4 (7.1 / 5.6 su contenitore) |
| `outline` (bordo input, ≥ 3:1) | `#6E6885` | `#8C869E` | 3.7 · 3.2 |
| `outlineVariant` / `surfaces.hairline` | bianco 10 % | `#2A1F5C` 10 % | decorativo |

### 2.3 Accent, ruoli e semantici

| Token | Scuro | Chiaro | Contrasto | Uso |
|---|---|---|---|---|
| `primary` (Accent, violetto elettrico) | `#B49CFF` | `#6A3DF0` | 8.6 · 5.4 | stato vivo, focus, link, selezione |
| `onPrimary` | `#1A0F3D` | `#FFFFFF` | 7.8 · 5.9 | testo su accent |
| `primaryContainer` | `#2B2350` | `#ECE6FF` | | sfondo toggle acceso, chip selezionato |
| `secondary` (Magenta) | `#F07BFF` | `#B026C9` | 8.4 · 4.9 | secondo stop Aurora, badge "nuovo" |
| `heat` (Coral) | `#FF8A6B` | `#B83A1F` | 8.5 · 5.3 | **solo** preferiti/love, "ascoltato di recente" |
| `tertiary` (Aqua) | `#4FE3D0` | `#0A7268` | 12.4 · 5.3 | info, download, offline, cache |
| `error` | `#FF6B7F` | `#D12A45` | 7.2 · 4.7 | errori, distruttivo |
| `success` | `#4ADE9B` | `#13784B` | 11.5 · 5.0 | server online, sync ok |
| `warning` | `#FFC25C` | `#A55A00` | 12.3 · 4.7 | server lento, degradato |
| Server dot | `serverHueSwatches` (§2.6) | | ≥ 3:1 | identità sorgente, mai stato |

`heat` sostituisce `favoriteIndicator` (`#EC4899`), `success` sostituisce
`playingIndicator` (`#1DB954`, verde Spotify: fuori brand). Il brano in
riproduzione si segnala con **accent**, non con verde.

### 2.4 Aurora — la firma

```
aurora      = linear 135°: #9479FF 0% → #E07BFF 55% → #FF8F6B 100%
auroraSoft  = aurora con alpha 18 %   (alone, focus glow, chip "now playing")
auroraMesh  = 3 radial: #6A3DF0 @ (0.2,0.1) r0.9 · #C04BE8 @ (0.9,0.3) r0.8 ·
              #F0644A @ (0.5,1.1) r0.9, ciascuno alpha 35 % (scuro) / 22 % (chiaro)
onAurora    = #14081F                  (5.9 · 7.8 · 8.7 sui tre stop)
```

Regole:
- Testo e icone su Aurora sono **sempre `onAurora`** (scuro), in entrambi i
  temi: il bianco scende a 3.2:1 sullo stop coral.
- In chiaro un riempimento Aurora ha anche filo `#2A1F5C` 12 % e ombra
  `glow` (§6): il gradiente da solo sul Pearl è a 2–3:1 come bordo.
- `auroraMesh` è lo **sfondo di riserva** di `ArtTintBackground` quando non
  c'è copertina (Settings, server, empty state, onboarding): deriva lenta 20 s,
  ferma con reduce motion.
- Codice: nuova `ThemeExtension` `OmnisonicBrand` (`aurora`, `auroraSoft`,
  `auroraMesh`, `onAurora`, `heat`, `glow`). I vecchi `primaryGradient`,
  `heroGradient`, `accentGradient`, `nowPlayingGradient`,
  `progressBarGradient`, `*AnimatedGradient`, `cardDepthGradient`,
  `glassMorphism*` vengono rimossi.

### 2.5 Su copertina

Invariato: tutto ciò che sta sopra un'immagine usa `scrim` / `scrimStrong` +
`onScrim` / `onScrimMuted`, in entrambi i temi. Il Play sopra copertina è
Aurora (`onAurora`) con ombra `glow`.

### 2.6 Server dot

Otto tinte che evitano rosso/arancio/giallo (si leggono come errore) e il
violetto/magenta dell'Aurora (si leggerebbero come "in riproduzione" o brand).
Ordinate perché due server vicini abbiano tinte distanti.

- **Scuro** (oklch L .74 C .15, 7.8–11.5:1 su Midnight): `#5AA9F0` · `#4FD6A0`
  · `#4FD0DE` · `#A7D45A` · `#8FA2FF` · `#5CC9C0` · `#C6B25A` · `#7FB8E8`.
- **Chiaro**: stesse tinte a oklch L .52 (≥ 3:1 su Pearl; le versioni scure
  scendono a 1.6–2.3:1). Esempi verificati: `#3F86D6` 3.4:1. I valori esatti
  si calcolano in D1 e finiscono nel test di contrasto.

`serverColorFor` diventa `serverColorFor(id, {index, brightness})`.

---

## 3. Tipografia

Tre famiglie, tre voci (invariate). Due aggiunte: un **display** per gli hero
e i numeri **tabulari** ovunque ci sia un tempo.

| Ruolo | Token | Famiglia | Size / peso / tracking | Dove |
|---|---|---|---|---|
| **Hero** *(nuovo)* | `heroTitle` | Gabarito | 56 / 800 / −1.6 (40 su telefono) | DetailHeader album/artista, Now Playing desktop |
| Titolo pagina | `pageTitle` | Gabarito | 40 / 800 / −0.8 | header schermata (≥ 480 px) |
| Titolo sezione | `sectionTitle` | Gabarito | 28 / 800 / −0.5 | sezioni Home |
| Titolo sezione compatto | `sectionTitleSmall` | Gabarito | 22 / 800 / −0.2 | telefono, rail |
| Titolo overlay | `overlayTitle` | Gabarito | 20 / 700 / −0.2 | dialog, sheet |
| Titolo di gruppo | `groupTitle` | Gabarito | 17 / 700 / 0 | "Tracks", sezioni Settings |
| Riga primaria | `titleMedium` | Manrope | 15 / 600 | ListTile, righe |
| Corpo | `bodyMedium` | Manrope | 14 / 400 / 0 | testo corrente |
| Corpo piccolo | `bodySmall` | Manrope | 12 / 500 / 0 | sottotitoli, artista |
| Bottone | `button` | Gabarito | 14 / 700 / 0 (16 per `lg`) | bottoni |
| Etichetta nav | `navLabel` | Gabarito | 13.5 / 600 | sidebar, tab |
| Card | `cardTitle` / `cardSubtitle` / `cardMeta` | Manrope / Manrope / Mono | 13·12·11 | MediaCard |
| Dato tecnico | `technical` / `technicalSmall` | JetBrains Mono | 12 / 11, 600, `tnum` | bitrate, conteggi |
| **Tempo** *(nuovo)* | `timecode` | JetBrains Mono | 12 / 500, `tnum` | durate, posizione player — larghezza fissa, niente salti |
| Eyebrow | `eyebrow` | JetBrains Mono | 11 / 600 / +0.8, MAIUSCOLO | etichette di gruppo; in hero colore `primary` |

Pavimento: 11 px per etichette mono, 12 px per testo informativo. Titoli hero
su copertina: `onScrim` + ombra testo `0 1 12 #000 40 %`.

---

## 4. Spaziatura (4 pt)

Invariata.

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
| `artHero` *(nuovo)* | 20 | copertina hero (DetailHeader, Now Playing) |
| `xl` / `panel` | 20 | pannelli vetro, player bar |
| `xxl` / `overlay` | 24 | dialog, sheet, card "Riprendi" |
| `full` | ∞ | bottoni, chip, ricerca, avatar, artista |

**Bottoni e chip sempre a stadio** (`full`); i contenitori mai.

---

## 6. Elevazione, luce e materiali

Niente `elevation` Material: profondità = strato vetro + ombra dedicata. La v2
aggiunge la **luce colorata**: le cose vive emettono.

| Token | Valore | Uso |
|---|---|---|
| `OmnisonicShadows.art` / `artCompact` | invariati | copertine |
| `OmnisonicShadows.artGlow` *(nuovo)* | colore dominante copertina, alpha 35 %, blur 40, y 16 | copertina hero e Now Playing: la copertina "illumina" la tela |
| `OmnisonicShadows.glow` *(nuovo)* | `#C04BE8` 40 % blur 24 y 8 (scuro) / 22 % (chiaro) | bottone Aurora, focus del player |
| `OmnisonicShadows.focusRing` *(nuovo)* | 2 px `primary` + alone `auroraSoft` 4 px | focus da tastiera, ovunque |
| ombra `GlassSurface` | invariata | pannelli L1/L2 |
| `OmnisonicShadows.overlay` | invariata | dialog, sheet, menu |

`GlassSheen` (riflesso diagonale) resta solo su L1/L2 in scuro, opacità 4 %.
Con "riduci trasparenza" (iOS/macOS) il vetro diventa `surfaceContainer`
opaco.

---

## 7. Movimento

Durate (`AnimationManager`): `instant` 100 (press), `fast` 150 (hover,
stato), `quick` 200 (swap), `normal` 300 (spostamenti), `emphasis` 450
(apertura player, hero), `tint` 600 (cambio tinta copertina).

Curve: `standard` easeInOutCubic · `enter` easeOutCubic · `exit` easeInCubic
(uscite più rapide: 70 % della durata d'entrata) · `spring` (massa 1,
rigidità 380, smorzamento 30) per press e toggle.

Micro-interazioni canoniche:

| Interazione | Spec |
|---|---|
| Press bottone / card | scala 0.97 in `instant`, ritorno `spring` |
| Hover card (desktop) | copertina 1.03 + sollevamento ombra `art` → `artGlow` 50 %, `fast` |
| Toggle preferito | cuore outlined → filled `heat`, scala 1 → 1.25 → 1 `spring`, haptic leggero |
| Brano vivo | equalizer 3 barre `primary`, 900 ms loop sfasato; pausa = barre ferme a metà |
| Apri Now Playing | `Hero` copertina mini player → hero, `emphasis` |
| Griglia al primo caricamento | stagger 40 ms/elemento, max 12 elementi, fade + y 8 |
| Cambio tinta | crossfade `tint` |

Sempre via `AnimationUtils.adjustedDuration` (reduce motion → 0, equalizer e
mesh fermi). Mai spostamenti di layout al press.

---

## 8. Iconografia

Solo `OmnisonicIcons` (famiglia *rounded*; *outlined* = inattivo, *filled* =
attivo). Taglie: `inline` 14 · `sm` 16 · `smd` 20 · `md` 24 · `lg` 32 ·
`xl` 40 (Play hero). Target ≥ 44 × 44 sempre. Icone su Aurora: `onAurora`.

---

## 9. Componenti

Ogni componente dichiara gli stati **default · hover · pressed · focus ·
disabled · loading** (dove ha senso). Focus = `focusRing` ovunque.
Disabled = opacità 38 % del contenuto, nessuna ombra.

### 9.1 Bottoni

| Variante | Fill / testo | Hover · pressed | Uso |
|---|---|---|---|
| **Signature** *(nuovo, `AuroraButton`)* | `aurora` / `onAurora`, ombra `glow` | sheen +8 % · scala 0.97 | Play/Shuffle principale. **Uno per schermata.** |
| **Primary** (`FilledButton`) | ink / `surface` | +8 % overlay `surface` · scala 0.97 | Salva, Aggiungi server, Connetti |
| **Tonal** (`FilledButton.tonal`) | `well` + filo / `onSurface` | `wellHover` | azioni secondarie, "Shuffle" accanto al Play |
| **Outlined** | filo `outline` / `onSurface` | filo `onSurfaceVariant` | alternative neutre |
| **Text** | — / `onSurfaceVariant` | → `onSurface` + well | "See all", terziarie |
| **Destructive** | `error` / `onError` | — | conferma eliminazione (mai in prima vista) |
| **GlassInkButton** | vetro L2 / `onSurface` | — | search, "Sync now" sopra il vetro |

Taglie: `sm` h 36 (solo desktop con puntatore) · `md` h 44 · `lg` h 52.
Icona + etichetta: icona `smd`, gap `sm`. Loading: spinner 16 al posto
dell'icona, larghezza invariata, `Semantics(liveRegion)`.

### 9.2 IconButton

| Variante | Spec |
|---|---|
| `standard` | 44 × 44, icona `smd`, hover `onSurface` 8 % |
| `filled` | disco ink, icona `surface` |
| `tonal` | disco `well` |
| `onScrim` | disco `scrimControl`, icona `onScrim` (sopra copertina) |
| `toggle` | outlined ↔ filled; acceso = `primary` (o `heat` per preferito) |
| **Play disc** *(nuovo, `PlayDisc`)* | disco Aurora 48/56/64, icona `onAurora` `md`/`lg`; il Play di card, righe hero e transport |

Sempre `tooltip` + `Semantics(label)`.

### 9.3 Input e selezione

| Componente | Spec |
|---|---|
| **TextField** | pozzetto `well`, raggio 12, filo `hairline`; focus = filo `primary` 2 px + `focusRing`; errore = filo `error` + testo sotto |
| **SearchField** | stadio, h 48, icona 20; focus: alone `auroraSoft`; pulsante clear 44 |
| **Chip / FilterChip** | stadio, `well`, `labelMedium`; selezionato = `primaryContainer` + bordo `primary` 1 px + check |
| **Segmented** | contenitore `well` a stadio; segmento attivo = pillola ink che **scivola** (`quick`, `spring`) |
| **Switch** | track spento `surfaceContainerHighest`; acceso track `primary`, thumb `onPrimary`; 48 × 28 |
| **Checkbox / Radio** | 20, bordo `outline` 1.5; acceso `primary` |
| **Slider** (volume, generico) | track 4 `surfaceContainerHighest`, attivo `primary`; thumb 14 → 18 al drag |
| **Progress del brano** | track 4 → 6 al hover/drag, attivo **`aurora`**, buffer `onSurface` 20 %, thumb nascosto → 14 al hover/drag; tempi `timecode` |

### 9.4 Navigazione

| Componente | Spec |
|---|---|
| **Sidebar / rail** | vetro L1; voce h 44 raggio 12; selezionata = pillola `wellHover` + **barra Aurora 3 × 20** a sinistra + icona filled `onSurface`; hover = `well` |
| **Bottom nav** | vetro L2 a stadio, flottante a `chromeInset`; selezionata = pillola `wellHover` + icona filled + etichetta; indicatore che scivola |
| **DesktopTopBar** | trasparente su tela, vetro L2 dopo 8 px di scroll (fade `fast`) |
| **AccountMenu** | menu L3; avatar con anello stato server (success/warning/error) |

La pillola ink della v1 è sostituita: l'ink resta per le azioni, il "sei qui"
diventa vetro + barra Aurora (più leggibile e non compete col Primary).

### 9.5 Media

| Componente | Spec |
|---|---|
| **CoverArt** | raggio `art`/`sm` per taglia; segnaposto = gradiente placeholder con hue del seed + icona nota 40 % |
| **MediaCard / AlbumCard** | copertina + ombra `art`; hover: scala 1.03, overlay scrim 0→35 %, `PlayDisc` 48 che sale di 8 px in basso a destra; testo `cardTitle` 8 sotto; server dot in alto a sinistra solo se multi-sorgente |
| **ArtistCard** | cerchio, hover anello `auroraSoft` 2 px; nome centrato |
| **TrackRow** | h 56, thumb 48; hover `well`; **vivo** = equalizer al posto dell'indice + titolo `primary` + fondo `primaryContainer` 40 %; selezionato = `wellHover`; non disponibile (server offline) = 50 % + icona cloud-off + tooltip |
| **DetailHeader** | `ArtTintBackground` saturazione +15 % che sfuma nella tela; copertina `artHero` 240 (160 telefono) con `artGlow`; eyebrow `primary` ("ALBUM · 2024"); `heroTitle`; meta mono; riga azioni: `AuroraButton` Play + Tonal Shuffle + toggle preferito `heat` + overflow |
| **SectionHeader** | invariato (large/medium/small + TextButton) |
| **LibraryStatsRail** | tile `well` raggio 12; numero `sectionTitleSmall` tabulare; icona colore di ruolo (aqua per offline, heat per preferiti) |

### 9.6 Player

| Componente | Spec |
|---|---|
| **Mini player** (telefono) | vetro L2 a stadio sopra la bottom nav; tinta copertina 12 % nel vetro; progress 2 px `aurora` sul bordo inferiore; `PlayDisc` 44 |
| **Transport bar** (desktop) | vetro L2; sinistra copertina 56 + titolo/artista; centro `PlayDisc` 48 + prev/next/shuffle/repeat (toggle `primary`) + progress Aurora; destra volume, coda, testi, output |
| **Now Playing** | `ArtTintBackground` piena + `auroraMesh` 30 % sopra; copertina `artHero` con `artGlow`; titolo `sectionTitle`; progress Aurora 6; `PlayDisc` 64; azioni secondarie `onScrim` |
| **Badge qualità** | `MetadataChip` mono (`FLAC · 24/96`), `well`; lossless con bordo `tertiary` |

### 9.7 Overlay e feedback

| Componente | Spec |
|---|---|
| **Dialog** | L3, raggio 24, filo, ombra `overlay`; max 440; titolo `overlayTitle`; azioni a destra, primaria = Primary |
| **Bottom sheet** | L3, raggio 24 in alto, maniglia 36 × 4 `outlineVariant`; sopra mini player e nav |
| **Menu / popup** | L3, raggio 12, voci h 44, hover `well`, distruttive `error` |
| **Snackbar** | `inverseSurface`, raggio 12, flottante; icona per tipo (colore semantico); azione `inversePrimary` |
| **Tooltip** | `inverseSurface`, raggio 8, `bodySmall`, ritardo 500 ms |
| **InlineBanner** | pozzetto con bordo sinistro 3 colore semantico + icona; mai solo colore |
| **StatusChip** | stadio, tinta semantica 14 % + icona + etichetta |

### 9.8 Stati

| Componente | Spec |
|---|---|
| **Empty state** | `auroraMesh` tenue dietro; icona `xl` in disco `well` 80 con anello `auroraSoft`; `groupTitle`; corpo; azione Primary (o Signature se è l'unica azione, es. "Aggiungi server") |
| **Error state** | come empty, icona `error`, azione "Riprova" Tonal |
| **Skeleton** | `SkeletonBox` su `surfaceContainerHighest`, shimmer diagonale `white 6 %` 1500 ms; forme = componenti reali (card, riga, header) |
| **Loading inline** | `CircularProgressIndicator` 2 px `primary`; mai spinner a schermo pieno sopra contenuto già mostrato |

---

## 10. Impaginazione

Invariata dalla v1.

### 10.1 Due misure: chrome e gutter

- **`chromeInset` = 12**: distanza del chrome flottante dal bordo finestra e
  fra pannelli di chrome.
- **`gutter`**: margine orizzontale del contenuto, pubblicato dalla shell con
  `PageGutter` (telefono 16 / 20 da 480 px; accanto a sidebar 24).

### 10.2 Ritmo verticale

| Distanza | Valore |
|---|---|
| top pagina → titolo | `sm` 8 (telefono) / `md` 16 |
| titolo pagina → primo blocco | `ms` 12 |
| fra sezioni | `xl` 32 / `xxl` 40 |
| header sezione → contenuto | `ms` 12 |
| fondo pagina | `xxl` 40 (+ altezza mini player) |

### 10.3 Larghezze

- Griglie: `MediaGridPreset` (140–200 px per cella, gap 16).
- Caroselli: padding = `gutter`, scorrimento fino al bordo finestra.
- Contenuto da leggere: max **720 px**. Dialog: max 440 px.

### 10.4 Breakpoint

`ResponsiveBreakpoints`: 480 / 768 / 1024 / 1440. Le pagine chiedono a
`ShellLayout` / `PageGutter`, non a `MediaQuery`.

---

## 11. Accessibilità (gate per ogni PR di UI)

- Testo ≥ 4.5:1, testo grande e bordi di controlli ≥ 3:1 — in **entrambi** i
  temi; test di contrasto in `test/core/design_system/contrast_test.dart`.
- Target ≥ 44 × 44; gap ≥ 8 fra target adiacenti.
- `focusRing` visibile su ogni elemento focalizzabile; ordine di tab logico.
- Reduce motion: equalizer, mesh, stagger e scale → statici.
- Riduci trasparenza: vetro → opaco.
- `textScaler` 2.0 a 360 × 640 senza overflow.

---

## 12. Migrazione v1 → v2

| Area | v1 | v2 | Issue |
|---|---|---|---|
| Tela scura | `#0D0E10` neutro | `#0B0A12` Midnight | D1 |
| Tela chiara | `#EFEDEA` greige | `#F6F4FA` Pearl | D1 |
| Accent | `#A5A8FF` / `#4F46E5` | `#B49CFF` / `#6A3DF0` | D1 |
| Gradienti | 14 gradienti sparsi, quasi tutti inutilizzati | `aurora`, `auroraSoft`, `auroraMesh` | D1 |
| Preferito | `#EC4899` | `heat` `#FF8A6B` / `#B83A1F` | D1, D2 |
| In riproduzione | verde `#1DB954` | `primary` + equalizer | D1, D6 |
| Play principale | ink | `AuroraButton` / `PlayDisc` | D2 |
| Nav selezionata | pillola ink | `wellHover` + barra Aurora | D4 |
| Progress brano | `primary` piatto | `aurora`, 4 → 6 al hover | D7 |
| Focus | filo `primary` 2 px | `focusRing` (filo + alone) | D3 |
| Empty state / pagine senza copertine | tela piatta | `auroraMesh` | D10 |
