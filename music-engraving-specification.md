# Music Engraving Specification & Test Matrix

**Purpose:** This document enumerates the notational elements a MIDI-to-score engraving engine must handle correctly, organized so each item can become a discrete test case (input MIDI/musical construct → expected engraved output). It also proposes a comprehensive settings/preferences model so the engine's behavior is configurable rather than hard-coded.

Use this as a checklist: for each leaf item, construct a minimal MIDI file (or internal note-list) that exercises it, engrave it, and verify against standard engraving practice (Gould, *Behind Bars* is the reference convention used throughout unless noted).

---

## 1. Score Types & Layouts

The engine should be tested against each of these top-level score shapes, since layout, spacing, and part-extraction rules differ.

| Score type | Key requirements |
|---|---|
| Single-staff lead sheet (melody + chord symbols) | Chord symbol placement above staff, optional lyrics below |
| Piano (grand staff, 2 staves + brace) | Cross-staff beaming/notes, pedal markings, voice separation within a staff |
| Single instrumental part | Transposition (if transposing instrument), multi-rest consolidation, cue notes |
| Vocal solo + piano accompaniment | Lyric alignment to noteheads, melisma lines |
| SATB choral (open score or closed score) | 4 voices on 2 staves (closed) vs. 4 staves (open); stem direction per voice; multiple lyric verses |
| Small ensemble score (e.g., string quartet) | Bracket/brace grouping, instrument name abbreviation on subsequent systems |
| Full orchestral score | Standard instrument ordering (woodwinds, brass, percussion, strings), transposing instruments displayed at written pitch, cross-staff/system alignment (barlines lock across all staves), condensed vs. expanded percussion |
| Percussion-only part/score | Unpitched staff (single line or standard 5-line with per-instrument notehead shapes/positions), drum-set legend |
| Guitar/bass with tablature | Standard notation + tab staff pairing, fret/string numbering, bend/slide symbols |
| Lead sheet with repeats/road map | Rehearsal marks, multiple endings, segno/coda navigation |
| Chord-chart-only (no melody) | Slash notation, rhythm-slash notation with stems |

**System/page layout tests:**
- Automatic system breaks based on measure width and page size
- Manual system/page break honoring
- Multi-movement documents (title/tempo changes mid-score)
- Instrument name/abbreviation display: full name on system 1, abbreviation thereafter (configurable)
- Grand staff brace, ensemble bracket, sub-bracket for instrument families
- First-system indent vs. subsequent systems
- Justification of the last system (should not force full-width stretch)

---

## 2. Clefs

Test each clef in isolation and in combination (e.g., piano LH bass/RH treble; cello switching clefs mid-piece).

- Treble (G) clef
- Bass (F) clef
- Alto (C) clef (viola)
- Tenor (C) clef (cello/bassoon/trombone upper range)
- Soprano/Mezzo-soprano/Baritone C-clefs (historical/edge case — at minimum should not crash, ideally supported)
- Treble clef, octave up (8va, tenor voice)
- Treble clef, octave down (8vb, e.g., tenor voice notated an octave higher than sounding)
- Bass clef, octave up/down (8va/8vb) — e.g., contrabass
- Percussion clef (neutral clef, 2 thick vertical bars)
- Tablature clef (TAB)
- **Mid-piece clef changes:** correct placement (immediately before the note it applies to, or at end of prior system + courtesy clef at start of next system when the change falls at a system break)
- **Courtesy clef** at end of a system when a change occurs at the start of the next system
- Clef change interacting with accidentals (pitch spelling must stay correct across the change)

---

## 3. Key Signatures

- All 15 major/minor key signatures (0–7 sharps, 0–7 flats), correct ordering of sharps (F C G D A E B) and flats (B E A D G C F)
- Key signature placement relative to clef and time signature
- Courtesy key signature at end of system before a key change
- Key signature changes mid-piece (naturals used to cancel previous accidentals per convention, e.g., going from sharps to flats or to C major)
- Non-standard/atonal: no key signature (explicit naturals or accidental-per-note handling)
- Key signature on each staff in a multi-staff score (and correct suppression/adjustment for transposing instruments)
- Courtesy accidentals convention (configurable) after a barline for notes altered earlier in a previous measure, or across ties into a new measure

---

## 4. Time Signatures

### 4.1 Simple meters
- 2/4, 3/4, 4/4 (and 4/4 displayed as "C" common time, configurable)
- 2/2 (cut time, "¢")
- 3/8, 2/2, 5/4, etc. — general simple meters with any single-digit or double-digit numerator/denominator

### 4.2 Compound meters
- 6/8, 9/8, 12/8
- Correct default beat grouping (dotted-quarter beat, beams in groups of 3 eighths)

### 4.3 Complex / additive / irregular meters
- 5/8, 7/8, 11/8 with explicit or implied beat groupings (e.g., 7/8 as 2+2+3 vs 3+2+2) — engine should support a user/inferred grouping that drives beaming
- 5/4, 7/4 with internal grouping

### 4.4 Other
- Irrational/non-power-of-2 denominators if supported by source (e.g., 2/3) — at minimum graceful handling
- Mixed/changing meter every measure (meter changes mid-piece, correct redraw of time signature)
- Courtesy time signature at end of system before a change
- Pickup measure / anacrusis (partial first measure, correct final-measure completion accounting so total duration reconciles, "measure 0" numbering behavior)
- Cadenza / unmetered (free time) passages — no barlines or dashed barlines, no beaming-to-meter constraints
- Polymeter (different simultaneous time signatures per staff) — edge case, at minimum should not corrupt other staves
- Metric modulation markings (equivalence between note values across a tempo/meter change) — at least tolerate as a text/symbol annotation

---

## 5. Note Durations & Rhythm

### 5.1 Base durations (and matching rests)
- Double whole note / breve (and rest)
- Whole note (and rest)
- Half note (and rest)
- Quarter note (and rest)
- Eighth note (and rest)
- 16th note (and rest)
- 32nd note (and rest)
- 64th note (and rest)
- 128th note (and rest) — at least non-crashing support
- Multi-measure rest (consolidated rest with measure count, common in parts)

### 5.2 Augmentation
- Single dotted notes/rests (all durations above)
- Double-dotted notes/rests
- Triple-dotted (rare, but should not break)
- Ties (note-to-note, including ties across barlines, ties across systems, ties across a clef/key change, chains of ties)
- Tie vs. slur disambiguation (same-pitch consecutive notes = tie; test the engine doesn't merge a tie improperly with an overlapping slur)

### 5.3 Tuplets
- Triplets (all base durations: eighth-note triplet, quarter-note triplet, 16th-note triplet)
- Duplets (in compound meter)
- Quintuplets, septuplets
- Nested tuplets (tuplet within a tuplet)
- Tuplet bracket vs. number-only display (configurable), bracket suppressed when beam already groups the tuplet clearly (convention-dependent, should be a setting)
- Irregular/non-standard ratios (e.g., 7:4, 5:2)

### 5.4 Beaming
- Correct default beam groupings per time signature (e.g., 4/4 beams in groups of 2 or 4 depending on style setting; 6/8 in groups of 3)
- Beam breaks at beat boundaries per meter
- Secondary beam breaks (partial beams / "flags" shown as broken secondary beams to indicate subdivision, e.g., a 16th following a dotted-8th)
- Cross-beat beaming when explicitly notated in source (should be able to represent syncopation with a single beam spanning a beat when convention/setting allows)
- Beam angle/slant rules for ascending/descending groups, and "flat beam" thresholds for wide pitch spans
- Beaming across rests (beam-over-rests as a style option, default off per Gould)
- Cross-staff beaming (piano/harp passages crossing between the two staves)
- Beamlets on isolated 16ths/32nds outside a beam group

### 5.5 Stem direction & multi-voice
- Single voice: stem direction based on notehead position relative to the middle line
- Two independent voices on one staff (e.g., SATB closed score, piano voices): voice 1 stems up, voice 2 stems down, correct rest positioning to avoid collision
- Voice collision resolution: noteheads offset horizontally when voices share a pitch/close interval
- Shared noteheads when two voices have identical pitch and duration (optional unison merge, should be a setting)
- Three and four independent voices on a single staff

---

## 6. Rests

- Correct vertical placement per clef and per voice (voice 1 rests high, voice 2 rests low, on a shared staff)
- Whole-measure rest centered in the measure regardless of time signature (except explicit multi-rest/duration edge cases)
- Rest merging into full-measure rest when a single voice's content for a measure is entirely rest
- Multi-measure rest with count number, and the "gap" barline style used for long multi-rests in parts

---

## 7. Accidentals

- Sharp, flat, natural, double-sharp, double-flat
- Microtonal accidentals (quarter-tone up/down, etc.) if the source format supports pitch bends/microtuning — at minimum should not silently round without flagging
- Accidental persistence through a measure (applies to all same-pitch notes in that measure, same octave only) and cancellation at the next barline
- Accidental re-statement across a tie into a new measure (courtesy accidental convention, configurable)
- Courtesy accidentals in parentheses (e.g., reminder accidental after a natural sign was used earlier, or after an octave change) as a configurable feature
- Correct enharmonic spelling selection from raw MIDI pitch numbers (critical: MIDI has no key/spelling information, so the engine's pitch-spelling algorithm must be tested against key context, e.g., C#4 vs Db4 chosen based on active key signature and melodic context)
- Accidental stacking/offset when multiple accidentals occur in a chord (avoiding collisions, correct left-to-right ordering by pitch)
- Cautionary/editorial accidentals in brackets

---

## 8. Articulations & Performance Markings

- Staccato (dot)
- Staccatissimo (wedge)
- Tenuto (line)
- Accent (>)
- Marcato (^)
- Combined articulations (accent + staccato, tenuto + staccato "louré")
- Placement above/below notehead based on stem direction and voice
- Fermata (over barline/final note, over rests)
- Breath mark / caesura
- Slurs: simple, phrase-spanning multiple measures, spanning a system break, nested slurs, slur vs. tie disambiguation (see 5.2)
- Slur/tie curvature avoiding collision with noteheads, stems, articulations, and other slurs
- Glissando / portamento lines (straight or wavy)
- Bend, slide (guitar tab-specific)

---

## 9. Ornaments

- Trill (tr with optional wavy extension line, optional accidental above the trill sign for the auxiliary note)
- Mordent (upper and lower)
- Turn (standard and inverted), placement above the note vs. between notes
- Grace notes: acciaccatura (slashed, single small note with slur to main note), appoggiatura (unslashed)
- Multiple grace notes (grace-note groups, beamed together, slashed or not)
- Grace notes on the beat vs. before the beat (rhythmic placement/timing interpretation from MIDI)
- Arpeggiation marks (wavy vertical line before a chord; with/without arrow indicating direction)
- Tremolo (single-note tremolo via slashes through the stem; two-note/measured tremolo between alternating notes/chords)
- Trill with termination (turn at the end of a trill line)

---

## 10. Dynamics

- Standard marks: ppp, pp, p, mp, mf, f, ff, fff (and beyond, e.g., ffff/pppp)
- Sforzando/sforzato (sfz, sf), fp, rfz
- Hairpins (crescendo/diminuendo wedges), including hairpins spanning a system break (terminate at system end, resume at system start), hairpin-to-dynamic-mark handoff
- Dynamic placement (below staff by default for most instruments, above for e.g. double bass in ensemble/some conventions — configurable per instrument)
- Terraced dynamics vs. hairpin combined with text (e.g., "cresc. poco a poco")

---

## 11. Tempo & Expression Text

- Tempo marks (e.g., quarter = 120), correct note-value glyph rendering matching the prevailing beat unit
- Tempo text (Allegro, Andante, etc.) with or without metronome mark
- Ritardando/accelerando text and dashed continuation lines
- Rehearsal marks (boxed/circled letters or numbers, auto-incrementing)
- Metric modulation text
- Generic expressive text (dolce, cantabile, etc.) and its default placement (above staff)

---

## 12. Repeats & Navigation ("Road Map")

- Repeat barlines (start/end repeat, forward and backward)
- Multiple (voltas) endings — 1st/2nd ending brackets, correct bracket numbering and open/closed bracket ends
- D.C. (Da Capo), D.S. (Dal Segno), D.C./D.S. al Fine, al Coda
- Segno and Coda symbols, and correct navigation logic when generating a "playback order" or when validating that a MIDI performance matches the notated road map
- Simile marks (repeat previous measure/beat — % and double-measure repeat symbols)
- Codetta / multiple coda symbols in sequence

---

## 13. Barlines & Measures

- Standard, double (section end), final barline
- Dashed/dotted barline (informal subdivision, e.g., in irregular meters or cadenzas)
- Repeat barlines (see §12)
- Courtesy/system-end barline behavior
- Barline suppression within a measure for unmetered passages
- Pickup measure barline positioning (see §4.4)
- Cross-staff/system barline alignment across all instruments in a multi-staff score
- Measure numbering (every measure, every N measures, system-initial only — configurable) and pickup-measure numbering convention

---

## 14. Chords, Voicing & Noteheads

- Chord stacking with correct interval offset (seconds notated on alternating sides of the stem)
- Notehead shapes: normal, diamond (harmonics), "x" (percussion/muted), slash (rhythm), triangle, other unpitched shapes used in percussion legends
- Stem-side notehead placement consistency within a chord
- Unison/enharmonic collision within a chord (e.g., C# and Db in same chord)
- Cluster chords (seconds stacked densely)
- Guitar chord diagrams (if in scope) alongside standard notation

---

## 15. Lyrics & Text Underlay

- Single verse alignment (syllable-to-note), hyphenation between syllables of a word, elision (underscore/slur for melisma across multiple notes)
- Multiple verses stacked below the staff
- Lyric line extending beyond the note (word-extender line for held syllables)
- Lyric centering vs. left-alignment under the note relative to the notehead
- Chorus/refrain formatting differences (if applicable)

---

## 16. Chord Symbols (Lead Sheet)

- Root + quality (maj, min, dim, aug, sus, etc.), extensions (7, 9, 11, 13), alterations (♭5, #9, etc.)
- Slash chords (e.g., C/E)
- Placement above the staff, aligned to the correct rhythmic onset
- Chord symbol font/bracket conventions (configurable)

---

## 17. Transposition

- Transposing instrument display (e.g., Bb Clarinet, written a major second above sounding pitch; F Horn; Eb Alto Sax, etc.) with correct interval and octave displacement per instrument
- Concert-pitch vs. written-pitch score toggle
- Key signature adjustment for transposed parts (or "no key signature" convention sometimes used for some transposing brass parts — configurable)
- Octave clefs (8va/8vb lines) vs. actual clef choice for extreme-range instruments (e.g., piccolo, contrabassoon, guitar)

---

## 18. Percussion-Specific

- Unpitched single-line staff vs. 5-line staff with notehead-position-to-instrument mapping
- Drum set notation legend (standard positions for kick, snare, hi-hat, toms, cymbals)
- Multiple simultaneous percussion instruments on one staff, independent stems/voices per instrument
- Special noteheads (x for cymbals/hi-hat, circle-x for open hi-hat)

---

## 19. Multi-Instrument / Score-Wide Concerns

- Vertical alignment: identical rhythmic onset must align vertically across all staves in a system
- Spacing proportional to duration (standard music spacing algorithms — shorter durations closer together, with configurable spacing curve)
- Collision avoidance between staves (e.g., piano LH high notes vs. RH low notes, ledger lines from adjacent staves)
- Cue notes (small noteheads, from another instrument, during rests)
- Divisi within a section (string parts splitting into div. 1/div. 2)
- Instrument doubling indications (e.g., "Fl. 2 doubles Picc.")

---

## 20. MIDI-to-Notation Interpretation Layer

Since the input is MIDI (a performance/pitch-time format with no inherent notational metadata), the spec must include the *inference* rules, not just rendering rules:

- **Quantization**: snapping raw note-on/off times to a rhythmic grid at a configurable resolution (e.g., nearest 16th, nearest triplet-16th), with a tolerance/swing setting
- **Key detection**: inferring a key signature from pitch content (e.g., Krumhansl-Schmuckler or similar) when not explicitly provided, used to drive enharmonic spelling (§7)
- **Time signature detection/assumption** when not explicit in the MIDI file (default assumption, e.g., 4/4, and/or beat-tracking-based inference)
- **Voice separation**: splitting a single MIDI track with overlapping/polyphonic content into separate notated voices (e.g., melody vs. accompaniment) when required by the target layout (piano, SATB)
- **Enharmonic spelling algorithm** correctness across chromatic passages, modulations, and secondary dominants
- **Tuplet detection**: recognizing that a cluster of notes represents a triplet/quintuplet rather than forcing them into straight subdivisions
- **Grace note detection**: distinguishing very short duration notes intended as ornamental grace notes vs. legitimate short rhythmic values
- **Tempo map handling**: multiple tempo changes within the MIDI file reflected as tempo text/marks at correct locations
- **Channel/track-to-staff/instrument mapping**: correct assignment of MIDI channels or tracks to the right staff, clef, and transposition
- **Velocity-to-dynamics mapping** (optional feature): inferring dynamic markings from MIDI velocity data, with configurable thresholds
- **Controller data** (sustain pedal CC64, etc.) mapped to notated pedal markings on piano scores
- **Note overlap/rounding errors**: MIDI often has slightly imprecise durations (e.g., a "quarter note" that's actually 239 ticks instead of 240) — engine must round to the intended notated value without accumulating error across a measure (so total measure duration still reconciles exactly)

---

## 21. Settings / Preferences to Expose

A configuration model the user can adjust, grouped by domain. Recommended as a structured settings object so tests can be parameterized against each combination.

### 21.1 Global / Page
- Page size & orientation, margins
- Staff size (rastral size), scaling
- Systems per page (auto vs. fixed)
- Title/composer/header/footer text and placement
- Instrument name display: full / abbreviated / none, and on which systems
- Measure numbering: every measure / every N / system-start only / none; numbering style (boxed, circled, plain)
- Justification of final system (stretch vs. natural width)

### 21.2 Notation Style
- Common time displayed as "C"/"¢" vs. numeric 4/4, 2/2
- Beam grouping style per meter (e.g., 4/4 beamed in 2s vs. 4s) — user override per time signature
- Beam-over-rests: on/off
- Tuplet bracket display: always / when not clear from beaming / never; bracket vs. number-only
- Accidental style: standard vs. courtesy-accidental-heavy (Baroque/Urtext-style reminder accidentals)
- Accidental cautionary-parenthesis rules on/off
- Key signature cancellation convention (naturals shown vs. omitted when changing key)
- Multi-measure rest consolidation threshold (min. number of consecutive rest measures before consolidating) — parts vs. score behavior
- Grace note slash convention defaults
- Notehead style presets (standard, jazz "fat" noteheads, cross/slash for rhythm notation)
- Stem length / flag style defaults
- Dynamics placement default (above/below) per instrument type
- Ties vs. slurs collision-avoidance curvature aggressiveness (cosmetic, but worth a knob)

### 21.3 Layout / Spacing
- Horizontal spacing algorithm parameters (proportional spacing exponent, minimum note spacing)
- Vertical spacing between staves within a system (auto vs. fixed, collision-avoidance padding)
- System spacing (space between systems on a page)
- Cross-staff collision avoidance sensitivity

### 21.4 MIDI Interpretation
- Quantization grid resolution and tolerance/swing amount
- Tuplet detection sensitivity (thresholds for recognizing triplets/quintuplets vs. quantizing straight)
- Time signature: explicit-from-file vs. auto-detect vs. user-forced
- Key signature: explicit vs. auto-detect (with confidence threshold) vs. user-forced, per section if key changes
- Voice-separation strategy for polyphonic tracks (pitch-range split, track-per-voice, top-note melody extraction)
- Minimum grace-note duration threshold (below which a short note is treated as ornamental)
- Velocity-to-dynamics mapping on/off, and the velocity→dynamic-mark threshold table
- Controller-to-notation mapping (sustain pedal, etc.) on/off
- Track/channel-to-instrument/clef/transposition mapping table (manual override per track)

### 21.5 Instrument-Specific
- Transposition: concert pitch vs. written pitch toggle (global and per-instrument override)
- Clef choice/auto-clef-switching thresholds (e.g., cello switches to tenor/treble above a certain pitch range)
- Percussion notehead/staff-position mapping table (per drum-kit piece)
- Octave-line (8va/15ma) usage threshold (how many ledger lines before switching to an octave line) — configurable per instrument

### 21.6 Output / Export
- Part extraction (generate individual instrumental parts from full score, each with independent layout/page breaks/multi-rest settings)
- Concert-score vs. transposed-score export toggle
- File format targets (PDF, MusicXML, SVG, etc.) if applicable to the package's scope
- Accessibility: alt-text/semantic tagging of exported notation if targeted

---

## 22. Suggested Test Harness Structure

For implementers turning this into automated tests:

1. **Unit fixtures**: one minimal MIDI file (or note-list) per leaf bullet above, isolating a single feature.
2. **Combinatorial fixtures**: pairwise combinations most likely to interact (e.g., tuplet + cross-staff beam; tie + accidental + key change; grace note + ornament + slur).
3. **Regression corpus**: a small set of real-world pieces spanning genres (solo piano piece, string quartet excerpt, jazz lead sheet, SATB hymn, drum groove) to catch integration-level issues not visible in isolated unit fixtures.
4. **Golden-output comparison**: render to an intermediate representation (e.g., MusicXML or SVG) and diff against hand-verified reference output, since pixel-perfect PDF diffing is brittle; structural/semantic diffing catches correctness issues without over-constraining cosmetic layout.
5. **Settings matrix**: run the regression corpus through key setting permutations (e.g., beam grouping style × tuplet bracket style) to confirm settings actually change output as intended and don't cross-contaminate unrelated features.

---
