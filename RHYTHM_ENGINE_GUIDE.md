# Slonimsky Rhythm Engine Guide

This guide covers the rhythm and structure features introduced in the 2026 rhythm-engine
overhaul (commits `f8e539b`, `60ba5e7`, `3bfe9ee`): real meters with accent groupings,
meter cycles, isorhythm, Euclidean rhythms, phase-based parameter curves, and the
additive/subtractive pattern process.

All of these operate on the *pitch patterns* produced by the Slonimsky generators
(scales, intervals, modulations, etc.) — the pitch machinery is unchanged; these
features decide **when** those pitches sound, **how they are accented**, and **how the
pattern evolves over repetitions**.

---

## 1. Core concepts

- **Beats.** All durations and positions are measured in beats, where a quarter note
  = 1.0 beat (an eighth = 0.5, a dotted quarter = 1.5, a whole note = 4.0).
- **Onsets.** Every note has an explicit start time. Notes can overlap (chords), and
  silence is a first-class citizen:
- **Rests.** Rests are real events that occupy time. The piano roll draws them as
  faint hatched columns.
- **Cycle.** One repetition of the generated pattern. Cyclical curves and the pattern
  process both operate *per cycle*: each repetition of the pattern can differ from
  the last in a controlled way.

---

## 2. Meter and groupings

*Where: Rhythm & Meter panel → Meter Cycle (compact preset picker also in Basic Parameters)*

A meter is more than a number pair. In this engine a meter is:

- a **numerator / denominator** (any of 1–16 over 2, 4, 8, 16), plus
- **groupings** — an additive split of the numerator that defines the accent grid.

The groupings are what make asymmetric meters feel right:

| Meter | Groupings | Accented pulses | Feel |
|-------|-----------|-----------------|------|
| 7/8   | 2+2+3     | 1, 3, 5         | "dm-dm-da-da-da" (Balkan) |
| 7/8   | 3+2+2     | 1, 4, 6         | front-heavy |
| 5/4   | 3+2       | 1, 4            | *Take Five* |
| 6/8   | 3+3       | 1, 4            | compound duple |
| 11/16 | 3+3+3+2   | 1, 4, 7, 10     | aksak |

Notes that land on a grouping start get a velocity boost (the **Grouping Accent
Boost** slider, 0–32). The piano roll shades alternating grouping spans so you can
*see* the difference between 2+2+3 and 3+2+2.

**Example — a 7/8 groove:**
1. Rhythm & Meter → select the `7/8 (2+2+3)` preset.
2. Set Base Note Duration to Eighth (0.5 beats).
3. Set Accent Boost to ~20.
4. Generate: you'll hear the pattern pulse in 2+2+3. Change the groupings to 3+2+2
   with the steppers and regenerate — same notes, completely different groove.

---

## 3. Meter cycles

*Where: Rhythm & Meter panel → Meter Cycle*

A meter cycle is a repeating **sequence of bars**, each with its own signature and
groupings — e.g. `4/4 | 7/8 | 7/8 | 5/8`. Use **Add Bar / Remove Bar** (up to 8 bars),
pick a preset per bar, and tap a bar row to edit its beats/unit/groupings in detail.

The crucial behavior: the pitch pattern **does not restart at barlines**. It flows
continuously across the changing bars, so a fixed-length melodic figure is re-accented
differently on every pass — the classic Balkan/prog effect. Barlines, accent shading,
and exported MIDI all follow the bar sequence (the MIDI file contains a time-signature
event at every change, so your DAW shows the real meter map).

**Example — re-accenting a figure:**
1. Meter Cycle: `4/4` then add a second bar and set it to `7/8 (2+2+3)`
   (cycle = 7.5 beats).
2. Basic Parameters: Pentatonic scale, 1 octave; Base Note Duration: Eighth.
3. Generate. The pentatonic figure is 6 notes (3 beats) long — it never lines up the
   same way twice against the 7.5-beat meter cycle, so the accents keep migrating
   through the melody.

---

## 4. Rhythm modes

*Where: Rhythm & Meter panel → Rhythm Mode*

The rhythm mode decides how the pitch stream is placed in time.

### Uniform
Every note gets the Base Note Duration, back to back. This is the plain mode; the
duration picker supports sixteenth through whole, dotted, and triplet values.

### Isorhythm (talea / color)
The medieval technique, and the deepest well of the three. Two independent cycles run
against each other:

- the **color** — the pitch pattern from the generator, and
- the **talea** — a repeating list of durations you edit, where any entry can be a
  **rest** (rests occupy time but never consume pitches).

When the color and talea have different lengths, the same pitch keeps arriving with a
different duration, and the same duration keeps carrying a different pitch. The
sequence runs until the two cycles realign: a 7-note color against a 5-note talea
realigns after 35 notes of continuous, coherent variation. The footer under the talea
editor shows the computed length ("realigns every N notes").

**Example — a limping isorhythm:**
1. Rhythm Mode: Isorhythm.
2. Talea: `Quarter, Eighth, Eighth (rest), Quarter, Sixteenth` — five entries, one of
   them a rest (toggle "Rest" on the third row).
3. Scale: Diatonic (7 notes). The 7-pitch color against the 4 sounding talea slots
   realigns every 28 sounding notes.
4. Generate: the rest keeps punching holes in different places of the scale line.

### Euclidean
Bjorklund's algorithm distributes **k hits as evenly as possible over n steps** —
E(k, n). Almost every world-music rhythm falls out of it:

| Pattern | Result | Known as |
|---------|--------|----------|
| E(3, 8) | `x . . x . . x .` | tresillo (Cuba) |
| E(5, 8) | `x . x x . x x .` | cinquillo |
| E(2, 5) | `x . x . .` | khafif-e-ramal |
| E(7, 16)| `x . . x . x . x . . x . x . x .` | samba family |

Pitches are consumed in order on the hits; the silent steps become rests. Controls:
**Steps** (1–32), **Hits** (1–steps), **Rotation** (shifts the pattern's starting
point), **Step Duration**, and a live dot-strip preview of the grid.

**Example — tresillo bassline:**
1. Rhythm Mode: Euclidean; Steps 8, Hits 3, Rotation 0, Step Duration Eighth.
2. Scale: Minor Pentatonic, root C2 (36).
3. Generate: the pattern walks the pentatonic scale across a tresillo grid, with the
   off-steps as genuine rests.

---

## 5. Cyclical parameter curves

*Where: the "Cyclical" toggle next to individual parameters (Modulations, Intervals,
Basic, Expression panels, and the uniform-duration block)*

Any cycleable parameter can follow a **phase curve** instead of holding still. A curve
has:

- **Min / Max** — the value range to sweep,
- **Period** — how many pattern cycles one full sweep takes (1–64),
- **Shape** — *Ramp Up*, *Ramp Down*, *Triangle*, *Sine*, or *Random* (a deterministic
  random value per cycle, repeating every period).

The key idea is **phasing**: every curve runs on its own clock. Two curves with
periods 3 and 4 drift against each other and only line up again every 12 cycles — the
sequence automatically runs until all enabled curves realign (least common multiple of
the periods, capped at 64 cycles). The caption under the editors shows the realignment
length.

**Example — Reich-style interference:**
1. Basic → Root Note → Cyclical on: Min 60, Max 72, Period 3, Ramp Up.
2. Modulations → Interpolation on, then its Cyclical toggle: Min 0, Max 3, Period 4,
   Triangle.
3. Generate: 12 cycles in which the register climbs on a 3-cycle loop while the
   ornament density breathes on a 4-cycle loop — they realign only at the end.

**Example — rotating Euclidean groove:**
1. Rhythm Mode: Euclidean, E(5, 8).
2. Tick **Cyclical Rotation (rotate grid each cycle)**. The rotation advances one step
   per cycle and comes full circle after 8 cycles — the same five hits continuously
   migrating around the grid.

---

## 6. Pattern process (additive / subtractive / pendulum)

*Where: Rhythm & Meter panel → Pattern Process*

The Philip Glass move: instead of playing the whole pattern every cycle, the pattern
**grows or shrinks by a fixed number of notes per cycle**.

- **Additive** — cycle 1 plays the first *Starting Notes* notes; each following cycle
  adds *Notes per Cycle* more until the full pattern is reached: `1, 12, 123, 1234…`
- **Subtractive** — starts with the full pattern and strips notes away down to one.
- **Pendulum** — grows to the full pattern, then shrinks back: `1, 12, 123, 12, 1`.

Details worth knowing:
- The process works in every rhythm mode. In Euclidean or isorhythm modes the
  interleaved rests are kept up to the last sounding note, so the grid feel survives
  the truncation.
- The process alone is enough to trigger multi-cycle generation — you don't need any
  cyclical curves enabled.
- If curves *are* enabled, the process and the curves merge: an additive process
  needing 6 cycles plus a curve with period 4 produces a 12-cycle sequence
  (lcm), with both evolutions running simultaneously.

**Example — classic additive build:**
1. Scale: Pentatonic, 1 octave; Rhythm Mode: Uniform, Eighth notes.
2. Pattern Process: Additive, Starting Notes 1, Notes per Cycle 1.
3. Generate: `C — C-D — C-D-E — …` until the full figure sounds. Switch to Pendulum
   for the grow-and-collapse arc.

---

## 7. Reich techniques — phasing and construction

*Where: Rhythm & Meter panel → Phasing / Pattern Process*

### Phasing voices

Turn on Phasing and a **second voice** plays the same pattern, slipping ahead of the
first by a controlled amount each cycle until the two realign:

- **Discrete** (*Clapping Music*): voice 2 jumps whole grid steps per cycle. A
  12-step pattern shifting 1 step/cycle realigns after 12 cycles; the realignment
  joins the sequence-length lcm automatically.
- **Continuous** (*Piano Phase*): voice 2 drifts a fraction of a step per cycle
  (the Drift slider), passing through the blurred zones between lock points.

Voice 2 can be **transposed** (±12 semitones; +12 keeps the voices separable) and is
slightly softer by default. In the piano roll, voice 1 keeps its pitch-hue colors and
voice 2 renders in a fixed cool tint, so you can watch the patterns slide apart.
Voice 2 plays on **MIDI channel 2** (channel 1 is the harmony track, 9 the drums), so
exports open in a DAW as two separate parts.

### Construction — substitution of beats for rests

Two additional Pattern Process modes with a **fixed time footprint** (unlike
Additive/Subtractive, which grow and shrink the bar):

- **Construct** (*Drumming*): the pattern's positions come alive one at a time —
  rests become beats in an evenly-spread, *nested* order, so once a beat lands it
  never moves.
- **Reduce**: the reverse — beats fall silent one at a time until one remains.

Both work inside Euclidean and isorhythm grids, and both combine with phasing:
reduce + discrete phasing gives you a pattern hollowing out while a second voice
slips against it.

---

## 8. Custom melodies

*Where: Custom Melody panel (sidebar, below Basic Parameters)*

Instead of generated scales, you can enter **your own melody** as the base material —
everything else in the app then transforms it.

- **Step entry**: pick a note value from the palette (sixteenth through dotted half),
  then click keys on the on-screen keyboard — each click appends a note. The **Rest**
  button appends silence of the selected value. Octave stepper shifts the keyboard.
- **Time signature**: pick it right in the panel (the same meter the whole engine
  uses); the preview draws barlines and grouping shading from the meter cycle.
- **Preview**: a mini piano-roll of the entered melody — click any note or rest to
  delete it; Undo removes the last event; capacity caption shows beats used.
- **Limit**: 8 bars of the current meter cycle.

The transformation contract:

- Rhythm mode **Uniform** plays the melody **as entered** — durations and rests
  preserved exactly (internally the entered rhythm becomes a talea, so if mirror or
  modulations lengthen the pitch stream, your rhythm cycles against it isorhythmically).
- **Isorhythm / Euclidean** modes re-rhythm the melody's pitches with your explicit
  settings — enter a tune, then euclideanize it.
- Mirror, modulations, curves, meter cycles, processes, and phasing all treat the
  melody exactly like generated material: enter a two-bar motif, switch on discrete
  phasing, and it phases against itself (the *Entered Motif Phase* preset ships
  exactly that).

---

## 9. Rhythm library

*Where: Rhythms panel (sidebar, below Custom Melody)*

Around forty built-in grooves, each written on a step grid **in its native time
signature** and mapped to the General MIDI percussion notes.

| Family | Examples |
|---|---|
| Rock & Pop | Basic Rock, Four on the Floor, Half-Time, Rock Shuffle, Motown, Boom Bap |
| Funk | Funk Sixteenths, Purdie-style Shuffle, Disco |
| Jazz | Swing Ride, Jazz Waltz (3/4), Brush Ballad |
| Afro-Cuban | Son Clave 3-2 / 2-3, Rumba Clave, Cascara, Tumbao, Mambo Bell, Cha-Cha, Songo |
| Brazilian | Bossa Nova, Samba, Partido Alto, Baião |
| African Bell | Short Bell 6/8, Bembé 12/8, Highlife, Afro 12/8 Kit |
| Middle East & Balkan | Maqsum, Baladi, Ayub (2/4), Karsilama (9/8), Balkan 7/8, Kopanitsa (11/16) |
| Electronic | House, Techno, Breakbeat, Drum and Bass, Trap Hats, Two-Step Garage |
| Odd Meter | Take Five (5/4), Prog 7/8, Five-Eight Drive, Tresillo, Cinquillo |

**Browsing.** Filter by time signature and family; every row shows a dot-grid preview
of the pattern (lanes down, steps across, brighter dots for accents, faint columns on
the meter's grouping starts). **Selecting a rhythm also sets the app's time signature**
to the pattern's own, so a 9/8 groove is always heard in 9/8.

**Role**
- *Pattern Source* — the rhythm becomes the pattern, exactly like a custom melody, and
  every other panel transforms it.
- *Layer Under Pattern* — the rhythm plays simultaneously beneath your scale or melody
  pattern.

**Output**
- *Drum Kit (GM)* — each lane sounds its General MIDI note (Kick 36, Snare 38, Closed
  Hat 42, Ride 51, Claves 75 …) on **MIDI channel 10**, so exports open as a drum part
  in any DAW.
- *Pitched* — the rhythm supplies onsets and durations while the pitches come from the
  scale (or your custom melody): enter a tune, then play it on a bossa grid.

**Per-pattern controls**: mute individual lanes, rotate the whole groove by any number
of steps (the same idea as Euclidean rotation), and set the accent boost. The caption
lists the exact GM note numbers currently sounding.

Transformations apply as they do everywhere else — the *Karsilama Kit* preset builds a
9/8 groove up two hits per cycle with the additive process, and phasing works on a
groove just as it does on a melody.

---

## 10. Putting it all together — recipes

> **Tip:** the **Presets** panel (top of the sidebar) ships one-tap versions of
> these ideas: a "Rhythm Engine Showcase" section (*Balkan Machine*, *Tresillo
> Bass*, *Machaut in Five*, *Glass Pendulum*, *Phase Music*, *Odd-Time Traveler*)
> a "Reich Showcase" section (*Clapping Pattern*, *Piano Phase*, *Drumming
> Build*, *Phase & Fade*) and a "Rhythm Library" section (*Clave & Motif*,
> *Karsilama Kit*, *Bossa Pitched*). Applying one loads every parameter panel, so you can
> inspect exactly how it's built and tweak from there.

### "Balkan machine"
| Setting | Value |
|---|---|
| Meter Cycle | `7/8 (2+2+3)` single bar |
| Rhythm Mode | Euclidean E(5, 8), Step Duration Eighth |
| Cyclical Rotation | on (full turn every 8 cycles) |
| Accent Boost | 24 |

The five hits rotate through the 7/8 accent grid; every cycle the hits land on a
different mix of strong and weak pulses.

### "Machaut in odd time"
| Setting | Value |
|---|---|
| Meter Cycle | `5/4 (3+2)` |
| Rhythm Mode | Isorhythm, talea `Quarter, Quarter, Eighth, Eighth (rest), Half` |
| Scale | Dorian, 1 octave |

A 14th-century talea against a jazz meter: the rest and the long note keep landing on
different scale degrees, re-punctuating the mode every pass.

### "Glass, phased"
| Setting | Value |
|---|---|
| Meter Cycle | `4/4` then `7/8 (2+2+3)` |
| Rhythm Mode | Uniform, Eighth |
| Pattern Process | Pendulum, Start 1, Step 1 |
| Root Note curve | Min 60, Max 67, Period 3, Sine |

Three evolutions at once: the pattern grows and collapses, the register swells on a
3-cycle sine, and the alternating 4/4–7/8 bars re-accent whatever the other two
produce. Everything realigns at the lcm of the process length and the curve period.

---

## 11. Seeing and exporting the results

- **Piano roll** (bottom pane, resizable): onset-accurate notes, thick barlines that
  follow the meter cycle, alternating grouping shading, brighter/outlined accented
  notes, hatched rest columns. Zoom with the +/− controls.
- **MIDI export**: notes are written at their true onsets (chords and rests survive),
  the tempo track carries a time-signature meta event at every meter change, so
  imported files show the correct, changing meter in any DAW.
- **External MIDI**: events are sent as an onset-sorted on/off queue, so overlapping
  notes and layered generator combinations play correctly on hardware.

---

## 12. Quick reference

| Feature | Panel | Key controls |
|---|---|---|
| Meter & groupings | Rhythm & Meter | numerator/denominator, grouping steppers, accent boost |
| Meter cycles | Rhythm & Meter | Add/Remove Bar, per-bar presets, selected-bar editor |
| Uniform durations | Rhythm & Meter | Base Note Duration (16th–whole, dotted, triplets) |
| Isorhythm | Rhythm & Meter | talea rows (duration + rest toggle), realignment footer |
| Euclidean | Rhythm & Meter | steps / hits / rotation, step duration, dot preview |
| Parameter curves | per-parameter "Cyclical" | min/max, period (cycles per sweep), shape |
| Euclidean rotation cycling | Rhythm & Meter | "Cyclical Rotation" toggle |
| Pattern process | Rhythm & Meter | mode (incl. Construct/Reduce), starting notes, notes per cycle |
| Phasing voices | Rhythm & Meter | mode (Discrete/Continuous), steps or drift per cycle, voice-2 transpose |
| Custom melody | Custom Melody | step entry, duration palette, rests, keyboard, 8-bar limit |
| Rhythm library | Rhythms | ~40 grooves, meter/family filters, GM drums or pitched, role, lane mutes, rotation |

*Sequence length rules:* curves realign at the **lcm of their periods**; a pattern
process contributes its own cycle count; both merge via lcm, capped at **64 cycles**.
Isorhythm realignment within a single cycle is capped at **1024 events**.
