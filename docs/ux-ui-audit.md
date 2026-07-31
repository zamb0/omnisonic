# Omnisonic — Audit UX/UI

Metodo: skill **ui-ux-pro-max v2.6.2** (84 stili, 161 palette, 99 linee guida UX, stack `flutter`).
Priorità della skill: 1 Accessibilità → 2 Touch/Interazione → 3 Performance → 4 Stile → 5 Layout/Responsive → 6 Tipografia/Colore → 7 Animazione → 8 Form/Feedback → 9 Navigazione → 10 Dati.

Superfici analizzate: `main_shell`, `feishin_shell`, `home_page`, `library_page`, `search_page`, `full_screen_player`, `animated_now_playing_bar`, `track_tile`, `album_card`, `empty_state`, `responsive_grid`, `theme.dart`, `colors.dart`, `typography.dart`, `responsive_layout.dart`, `app_router.dart`, `server_add_dialog`.

Verifica statica: `flutter analyze` → **265 issue** (98 `deprecated_member_use` in `lib/`, 33 `curly_braces`, 28 import inutilizzati, 5 `use_build_context_synchronously`, 2 error + 1 undefined in `test/`).

---

## Sintesi

L'app ha ossa buone: Material 3, tema chiaro/scuro completo, `EmptyState` con azione, shimmer in libreria, debounce 300 ms nella ricerca, `SafeArea` + seek con `onChangeEnd` nel player full-screen, tooltip sulle azioni desktop.

I problemi non sono estetici, sono **strutturali** e si concentrano su tre assi:

1. **Navigazione mobile incompleta** — su telefono sono raggiungibili solo Home, Albums, Search, Servers. Artists, Playlists e Starred non hanno alcun punto d'ingresso.
2. **Controlli finti** — shuffle, repeat, volume nella now-playing bar, "See all" nella ricerca, "opzioni album" in home: elementi tappabili che non fanno nulla.
3. **Design system fantasma** — 38 dei ~45 file di `lib/core/design_system/` non sono importati da nessuna schermata (~20k righe), i font dichiarati non sono nel bundle, e i token di touch target esistono ma la barra di riproduzione non li usa.

Conteggio per severità: **7 critici**, **9 alti**, **8 medi**, **6 bassi**.

---

## 1. Accessibilità (CRITICO)

### C1 — Coppie di colore che non passano WCAG AA nel tema chiaro
`lib/core/design_system/colors.dart:178-200`

Rapporti calcolati sui token di `lightColorScheme`:

| Coppia | Rapporto | Soglia | Esito |
|---|---|---|---|
| `onPrimary` bianco su `primary` #7C7CFF | **3.40:1** | 4.5 | fallisce |
| `onSecondary` bianco su `secondary` #6D6DFF | **3.98:1** | 4.5 | fallisce |
| `onTertiary` bianco su `tertiary` #4DD0E1 | **1.84:1** | 4.5 | fallisce anche 3:1 |
| `onError` bianco su `error` #EF4444 | **3.76:1** | 4.5 | fallisce |
| bianco su `success` #10B981 | **2.54:1** | 4.5 | fallisce anche 3:1 |
| bianco su `warning` #F59E0B | **2.15:1** | 4.5 | fallisce anche 3:1 |
| testo/icona `primary` su superficie bianca | **3.40:1** | 4.5 | fallisce |
| `Colors.red` (favorite) su `surfaceDark` | **4.47:1** | 4.5 | fallisce di misura |

Impatto: ogni `ElevatedButton`/`FilledButton`, l'icona di navigazione selezionata, i chip di stato server e il cuore "preferito" sono sotto soglia. Il tema scuro invece è a posto (`onSurfaceDark` #C9C9C9 su #1F1F21 = 9.94:1).

Fix: scurire i toni per il tema chiaro mantenendo l'hue (es. `primary` #4F46E5 → 6.4:1 con bianco, `success` #047857, `warning` #B45309, `error` #DC2626) e tenere le versioni chiare attuali come `*Container`/varianti per il tema scuro. Sostituire `Colors.red` con un token semantico `favoriteIndicator` già presente in `OmnisonicColors`.

### C2 — Barra di riproduzione senza etichette per screen reader
`lib/features/playback/presentation/widgets/animated_now_playing_bar.dart:587-601`

`_iconBtn` produce `InkWell` + `Icon` puri: nessun `Semantics`, nessun `tooltip`. Play/pausa, prev, next, preferito, coda, volume sono annunciati come elementi senza nome. È il controllo più usato dell'app.

Fix: usare `IconButton` con `tooltip` (che fornisce anche la semantica) oppure avvolgere in `Semantics(button: true, label: ...)`; per play/pausa etichetta dinamica ("Riproduci"/"Pausa").

### C3 — `EmptyState` con colori hardcoded fuori dal tema
`lib/features/ui/presentation/widgets/empty_state.dart:27,31,38`

`Colors.grey[400]`, `Colors.grey[600]`, `TextStyle(fontSize: 18/14)` invece dei token. In tema scuro il sottotitolo #757575 su sfondo #141414 dà **4.13:1**, sotto soglia; il testo ignora `textTheme`.

Fix: `colorScheme.onSurfaceVariant` + `textTheme.titleMedium`/`bodyMedium`.

### C4 — Indicatore di qualità illeggibile
`lib/features/playback/presentation/widgets/full_screen_player.dart:389-402`

`Opacity(0.6)` su `onSurfaceVariant` con `fontSize: 10`. Doppia violazione: testo sotto 12 px e contrasto risultante sotto 3:1.

Fix: rimuovere `Opacity`, usare `labelSmall` (11-12 px) con `onSurfaceVariant` pieno; se serve gerarchia, ridurre il peso, non l'alpha.

### C5 — Preferenze di riduzione del movimento mai applicate
`lib/core/design_system/accessibility_preferences.dart` (dead code)

Il file implementa `reducedMotionEnabled` leggendo anche `accessibilityFeatures.reduceMotion`, ma non è importato da nessuna schermata. `AnimatedSwitcher`, `SlideTransition`, shimmer e transizioni di rotta girano sempre.

Fix: leggere `MediaQuery.disableAnimationsOf(context)` nei punti di animazione (o esporre le preferenze via provider) e azzerare le durate.

---

## 2. Touch e interazione (CRITICO)

### C6 — Target di tocco 26-36 px nella barra di riproduzione
`animated_now_playing_bar.dart:255-280, 587-601`

- `_iconBtn`: icona 18-22 px + padding 4 → **26-30 px** di area tappabile (prev, next, preferito, coda, volume).
- Play/pausa: `Container` 36×36 con `IconButton` a padding zero → **36 px**.

Minimo richiesto: 44 pt iOS / 48 dp Android. Il progetto ha già i token giusti in `OmnisonicTouchTargets` (`minimum = 44`, `iconButton = 48`, `playButton = 56`) e non li usa qui. Sul mobile prev/next sono anche adiacenti con soli 4 px di gap (minimo 8).

Fix: `IconButton` con `constraints: BoxConstraints(minWidth: 44, minHeight: 44)` e gap ≥ 8; play/pausa a 48-56.

### C7 — Controlli che sembrano attivi e non fanno nulla
| Elemento | File |
|---|---|
| Shuffle nella barra → `() {}` | `animated_now_playing_bar.dart:436` |
| Repeat nella barra → `() {}` | `animated_now_playing_bar.dart:473` |
| Icona volume → `() {}` | `animated_now_playing_bar.dart:565` |
| Slider volume → `value: 0.7` fisso, `onChanged: (value) {}` | `animated_now_playing_bar.dart:579` |
| "See all" tracce/album/artisti → SnackBar segnaposto | `search_page.dart:443-465` |
| "Add to Playlist" → "Coming soon" | `search_page.dart:429` |
| `more_vert` sulla card album in home → no-op | `home_page.dart:355` |

Il paradosso: tutte le API esistono già. Shuffle e repeat **funzionano** nel player full-screen (`toggleShuffleMode`, `toggleRepeatMode`, `full_screen_player.dart:464-484`) e il volume ha getter + setter nel view model (`playback_view_model.dart:83, 585`). La barra ha solo il cablaggio mancante: lo slider mostra un `0.7` finto invece di `vm.volume` e scarta il valore invece di chiamare `vm.setVolume`.

Fix: collegare shuffle/repeat/volume al `PlaybackViewModel` (una riga ciascuno); nascondere "See all" e "Add to Playlist" finché non implementati, invece di mostrarli inerti.

### C8 — Azioni sulle card di home solo in hover
`home_page.dart:284-332`

`_HoverAlbumCard` mostra play/shuffle/opzioni solo su `MouseRegion.onEnter`. Su telefono e tablet quei tre comandi non esistono: il tap va al dettaglio album. L'overlay appare inoltre istantaneo (`if (_isHovered)`, nessuna transizione) e la card usa `GestureDetector` → nessun feedback di pressione al tocco.

Fix: `InkWell` per il feedback; long-press → menu contestuale con le stesse azioni su touch; `AnimatedOpacity` 150-200 ms per l'overlay.

---

## 3. Performance (ALTO)

### A1 — Ordinamento e deduplica dentro il `build`
`library_page.dart:106-111, 457-488`

`_dedupeAlbumsByServer` (hashmap su tutta la collezione) + `LibrarySortService.sortAlbums` girano a ogni rebuild del `Consumer2`, cioè a ogni cambio di filtro, di stato di sync e a ogni `notifyListeners` del view model. Con collezioni multi-server da migliaia di album è lavoro O(n log n) sul main thread per frame.

Fix: memoizzare nel view model (ricalcolo solo su cambio di sorgente/filtro/ordinamento).

### A2 — Le card della griglia sono costruite tutte, sempre
`responsive_grid.dart:47-90` + `library_page.dart:137-152`

`ResponsiveGridView` accetta `List<Widget> children`: il chiamante fa `.map(...).toList()` su tutta la collezione, quindi ogni rebuild istanzia N widget (il `GridView.builder` interno ne monta solo una parte, ma la lista è già materializzata). `ResponsiveGrid` (variante `Wrap`) è ancora peggio: monta tutto.

Fix: passare `itemCount` + `itemBuilder` invece di `children`.

### A3 — Seek continuo durante il trascinamento (desktop bar)
`animated_now_playing_bar.dart:511-516`

`Slider(onChanged: vm.seekToProgress)` invia una seek per ogni frame di drag. Il player full-screen fa la cosa giusta (`onChangeEnd`, `full_screen_player.dart:356-369`).

Fix: replicare il pattern `onChanged` locale + `onChangeEnd` per la seek reale.

### A4 — Skeleton di caricamento con geometria diversa dal contenuto
`library_page.dart:288-302`

`_buildLoadingGrid` è fisso a `crossAxisCount: 2`, `padding: 16`, `childAspectRatio: 0.8`; il contenuto reale usa `minItemWidth: 160` (fino a 6 colonne), `padding: 24`, ratio `0.72`. Su desktop si vedono due shimmer giganti che poi collassano in sei colonne: salto di layout a ogni sync.

Fix: usare `ResponsiveGridView` anche per lo skeleton, stessi padding/ratio.

---

## 4. Stile (ALTO)

### A5 — Il design system non è collegato all'app
38 file su ~45 in `lib/core/design_system/` non sono importati da nulla fuori dalla loro cartella: `accessibility*.dart`, `accessible_button.dart`, `platform_buttons.dart`, `enhanced_cards.dart`, `enhanced_lists.dart`, `enhanced_text.dart`, `loading_states.dart`, `error_states.dart`, `micro_interactions.dart`, `gesture_feedback.dart`, `animation_manager` (usato solo per 2 costanti), `typography.dart`, `orientation_handler.dart`, `platform_*`, più i file di esempio/demo (`*_examples.dart`, `cross_platform_demo.dart`, `checkpoint_test_app.dart`, `example_integration.dart`, `loading_feedback_examples.dart`).

Conseguenze concrete: ogni schermata reimplementa card, stati di caricamento, feedback e pulsanti a mano — da cui le incoerenze di questo audit — e ~20k righe (inclusi demo app) restano compilate nel bundle.

Fix (in ordine): eliminare i file demo/esempio da `lib/` (o spostarli in `example/`); adottare `AccessibleButton`/`loading_states`/`error_states` nelle schermate reali oppure cancellarli; tenere `theme/colors/spacing/typography/responsive_layout` come nucleo effettivo.

### A6 — I font del design system non sono nel bundle
`typography.dart:7-8` dichiara `'Inter'` e `'Poppins'`; in `pubspec.yaml:99-115` la sezione `fonts:` è **commentata** e `assets/fonts/` contiene solo un README. Tutta la tipografia ricade silenziosamente sul font di sistema (San Francisco/Roboto), quindi il tema tipografico voluto non è mai stato visto.

Fix: aggiungere `google_fonts` oppure i file .ttf e riattivare la sezione `fonts:`. Per un client musicale la skill suggerisce Poppins (body) + un display più caratterizzato (Righteous) — ma la scelta va fatta una volta e cablata, non dichiarata a metà.

### A7 — Palette non allineata al tipo di prodotto
La skill, per `product = Music Streaming`, raccomanda **Dark Mode (OLED) + accenti vivaci + colori derivati dalla copertina**, base #121212. Oggi: `backgroundDark` #141414 (ok) ma nessuna estrazione di colore dalla cover, `nowPlayingGradient`/`albumArtOverlay` definiti in `colors.dart` e **mai usati**, `themeMode: ThemeMode.system` senza possibilità di forzare dark (`main.dart:149`).

Fix a basso costo e alta resa: `palette_generator` sulla copertina → tinta del player full-screen e della now-playing bar; usare i gradienti già definiti; aggiungere un selettore di tema nelle impostazioni.

---

## 5. Layout e responsive (ALTO)

### A8 — Tre soglie di breakpoint diverse, in conflitto
| Punto | Soglia |
|---|---|
| `ResponsiveBreakpoints.mobile` | 480 (`responsive_layout.dart:5`) |
| `AnimatedNowPlayingBar.isMobile` | 600 (`animated_now_playing_bar.dart:83`) |
| `LayoutConfiguration` | 480/1024/1440 |

Tra 480 e 600 px di larghezza si ottiene la shell desktop (sidebar 264/76 px) **con** la barra di riproduzione in versione mobile. La sidebar da 264 px su una finestra da 500 px lascia ~236 px al contenuto. Riguarda telefoni in landscape, foldable e finestre desktop ridimensionate.

Fix: un'unica sorgente di verità (la skill suggerisce 375/768/1024/1440); shell desktop da ≥ 768, non da 480.

### A9 — Nessun `SafeArea` fuori dal player
Unica occorrenza: `full_screen_player.dart:48`. La bottom bar mobile (`main_shell.dart:24-36`: `Column` + `AnimatedNowPlayingBar` + `NavigationBar`) e le pagine non tengono conto di notch, Dynamic Island e barra dei gesti. `NavigationBar` gestisce da sé il padding inferiore, ma la now-playing bar sopra di esso e gli header delle pagine no.

Fix: `SafeArea` (o `MediaQuery.paddingOf`) sulle shell; verificare su iPhone con Dynamic Island e in landscape.

### A10 — Nav collassata solo a icone senza etichette raggiungibili
`feishin_shell.dart:184-199`

Nel breakpoint tablet la sidebar mostra solo icone; le etichette sono in `Tooltip`, che richiede hover — su un tablet touch sono inaccessibili. La skill lo classifica come `nav-label-icon` (danneggia la scopribilità).

Fix: etichette sotto l'icona nella versione compatta (stile `NavigationRail` con `labelType: all`).

---

## 6. Navigazione (ALTO)

### C9 — Su mobile mancano tre destinazioni su sei
`main_shell.dart:44-74` (bottom nav: Home, Library, Search, Servers) vs `feishin_shell.dart:76-141` (sidebar: Home, Search, Albums, Artists, Playlists, Starred, Servers).

`LibraryPage` cambia sezione solo tramite il query param `?tab=` (`library_page.dart:35-36`), impostato **esclusivamente** dalla sidebar desktop. Su telefono:

- **Artists** → irraggiungibile
- **Playlists** → irraggiungibile (la pagina esiste, `playlist_detail_page` compreso)
- **Starred/Favorites** → rotta `/favorites` registrata, nessun punto d'ingresso

Fix: `TabBar` (Albums/Artists/Playlists) nell'AppBar di `LibraryPage` sincronizzata col query param, e sostituire il tab "Servers" con "Starred" spostando i server in un ingresso secondario (impostazioni/overflow) — la skill classifica la configurazione come navigazione secondaria, non di primo livello.

### A11 — Stato attivo della bottom nav sbagliato
`main_shell.dart:76-93`

`_calculateSelectedIndex` mappa `albumDetail`/`artistDetail` su 1 e **tutto il resto su 0**: su `/favorites`, `/playlist-detail`, `/playlist-management` la barra evidenzia "Home". Le rotte di dettaglio sono anche hardcoded per indice: aggiungere un tab romperà la mappatura.

Fix: derivare l'indice da `location.startsWith(...)` con una tabella rotta→tab, e caso default a `null` (nessuna selezione) invece di 0.

### M1 — Deep link e rotta di errore
`app_router.dart` non definisce `errorBuilder`; `/album-detail` e `/artist-detail` fanno `state.extra as Album` (documentato in AGENTS.md), quindi un link condiviso o una notifica che apra quelle rotte crasha. Nessuna rotta ha un identificatore nell'URL: le schermate chiave non sono condivisibili (`deep-linking`).

Fix: path parametrico (`/album/:id`) con `extra` come sola ottimizzazione, fallback su fetch da id, più `errorBuilder`.

### M2 — Primo avvio senza via d'uscita
`home_page.dart:76-125` — con zero server tutte le sezioni tornano `SizedBox.shrink()`: la Home mostra "Home / Discover your music" e nient'altro. Nessun onboarding, nessuna CTA "Aggiungi server", `initialLocation: '/'` (`app_router.dart:32`). L'utente nuovo si trova davanti a una schermata vuota e deve scoprire da sé il tab Servers.

Fix: `EmptyState` in Home con azione "Aggiungi un server" quando `servers.isEmpty`; opzionale: redirect a `/servers` al primo avvio.

---

## 7. Form e feedback (MEDIO)

### M3 — Il pulsante "cancella" della ricerca non compare
`search_page.dart:81-89`

`suffixIcon` dipende da `_searchController.text.isNotEmpty`, ma il listener `_onSearchChanged` (righe 38-45) non chiama `setState`: il ramo `Scaffold` non viene ricostruito quando si digita (solo il `BlocBuilder` interno). La X compare/scompare in modo casuale, in base a rebuild causati da altro.

Fix: `setState` nel listener (o `ValueListenableBuilder` su `_searchController`).

### M4 — Feedback di sync senza esito
`library_page.dart:432-437` mostra "Syncing library..." e poi silenzio: nessun successo, nessun errore, nessun retry. Lo stesso pattern in `server_management_page.dart:569` ("Refreshing servers...").

Fix: SnackBar/banner conclusivo con esito e azione "Riprova" in caso di errore (`error-recovery`).

### M5 — Suggerimenti di ricerca finti
`search_page.dart:163-168` — chip hardcoded (Rock, Jazz, Classical, Electronic, Pop, Hip Hop) che non hanno relazione con la libreria dell'utente; nessuna cronologia delle ricerche recenti (raccomandata dalla skill: `search-accessible`). `MusicLibraryViewModel.genres` è già disponibile e usato nei filtri della libreria.

Fix: chip dai generi reali + ultime 5 ricerche persistite.

### M6 — Dialog di aggiunta server senza autofill
`server_add_dialog.dart:49-117` — label, validator e `obscureText` ci sono (bene), ma manca `autofillHints` (`AutofillHints.url`, `username`, `password`), quindi i gestori di password di sistema non intervengono su un form che chiede proprio delle credenziali.

Fix: aggiungere `autofillHints` e avvolgere in `AutofillGroup`.

---

## 8. Tipografia e animazione (MEDIO/BASSO)

### M7 — Testo sotto i 12 px nelle superfici principali
`animated_now_playing_bar.dart:218, 394, 404, 492, 524` — `fontSize: 11` per artista, album e timestamp; `full_screen_player.dart:397` — `fontSize: 10`. Su mobile la soglia è 12 px minimo (la skill chiede 16 px per il body).

### M8 — Cifre non tabulari nei timer
Posizione e durata (`_formatDuration` in `animated_now_playing_bar.dart:73-77`, `track_tile.dart:123-127`) usano cifre proporzionali: la larghezza cambia a ogni secondo e il layout balla.

Fix: `fontFeatures: [FontFeature.tabularFigures()]`.

### B1 — Stato disabilitato a opacità 0.3
`animated_now_playing_bar.dart:251, 278, 443, 469` — `withOpacity(0.3)` per prev/next disabilitati: sotto l'intervallo 0.38-0.5 di Material e senza semantica di disabilitazione (l'`onTap: null` la fornisce solo per `InkWell`, non per l'icona).

### B2 — Nessuna transizione condivisa copertina → player
Il `Hero` esiste solo in `album_detail_page.dart:348`. Il passaggio dalla now-playing bar al player full-screen (`main_shell.dart:29`) non ha continuità spaziale, che è la transizione più visibile di un client musicale.

### B3 — Nessuna gesture di dismissione del player
`full_screen_player.dart:171-184` — solo chevron; niente swipe-down (atteso su iOS/Android per una schermata modale a tutto schermo). Il pulsante è inoltre inerte se `!context.canPop()`.

### B4 — Scroll annidati nel player mobile
`full_screen_player.dart:93-113` — `SingleChildScrollView` che contiene un pannello a `height: 400` con dentro `ListView` (coda/testi): due regioni di scroll sovrapposte, conflitto di gesture.

### B5 — 98 usi deprecati in `lib/`
Principalmente `surfaceVariant` (→ `surfaceContainerHighest`, 31 occorrenze), `withOpacity` (→ `withValues(alpha:)`, 55), `background`/`onBackground` in `colors.dart`/`theme.dart`. Non sono difetti visibili, ma bloccano l'allineamento a Material 3 e nascondono i warning veri. In `test/` ci sono anche 3 errori di compilazione (`typography_system_test.dart:189`, `server_connection_test.dart:11`).

### B6 — Elementi di lista senza key
`full_screen_player.dart:596-667` (coda), `home_page.dart:161-172` (carousel): nessuna `ValueKey(track.id)`. Con liste riordinabili/mutabili lo stato dei figli si sposta (linea guida `flutter/Lists`).

---

## Piano consigliato

**Sprint 1 — credibilità (1-2 giorni)**
1. C9: `TabBar` in Library + Starred nella bottom nav (sblocca 3 sezioni su mobile).
2. C7: collegare shuffle/repeat nella barra; nascondere volume e "See all".
3. C1: correggere le 8 coppie di colore del tema chiaro.
4. C6: portare i controlli della barra a 44/48 px usando `OmnisonicTouchTargets`.
5. M2: CTA "Aggiungi server" nella Home vuota.

**Sprint 2 — solidità (2-3 giorni)**
6. A8: unificare i breakpoint; shell desktop da 768.
7. C2 + C3 + C4: etichette semantiche sulla barra, `EmptyState` e indicatore qualità sui token.
8. A1 + A2 + A3 + A4: memoizzare sort/dedup, griglie lazy, seek su `onChangeEnd`, skeleton coerente.
9. M3 + M4: fix del pulsante cancella, feedback di sync con esito.
10. A11: mappatura rotta→tab corretta.

**Sprint 3 — identità e pulizia (3-4 giorni)**
11. A5: rimuovere demo/esempi da `lib/`, decidere adozione o cancellazione dei ~20k righe di design system.
12. A6: cablare i font davvero.
13. A7: colore derivato dalla copertina + selettore di tema.
14. B2 + B3: transizione condivisa e swipe-down sul player.
15. B5: `dart fix --apply` per i deprecati, sistemare i 3 errori nei test.
16. C5 + A10: riduzione del movimento, etichette nella sidebar compatta.
