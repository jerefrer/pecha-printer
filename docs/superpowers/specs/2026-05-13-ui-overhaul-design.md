# Pecha Printer — UI Overhaul

**Date:** 2026-05-13
**Status:** Approved design, pending implementation plan

## Goal

Replace the current single-screen form (10+ controls visible at once, Shechen preset hidden in a help modal) with a focused interface optimised for the two real-world use cases — standard pecha printing and TibetDoc/Shechen exports — while keeping every existing option accessible for power users.

## Non-goals

- No new backend functionality. Every existing form field stays; only how the user reaches them changes.
- No design system or component library introduction. Pico CSS stays as the base; we override on the components that need it.
- No mobile-first redesign. The tool is used to drive a printer; desktop remains the primary target. The layout should not break on narrower viewports but tablet/phone is not a design priority.

## Users and use cases

1. **Standard pecha print (most common)** — user has a regular PDF, wants 3-up landscape with two-sided flipping. Picks A4 *or* A3 depending on their printer.
2. **Shechen-style print (common)** — user has a PDF exported from TibetDoc with crop marks; needs the very specific A3 / landscape / no-autoscale / no-margins / crop-from-marks combo.
3. **Custom (rare)** — every other combination of paper, layout, margins, autoscale, etc.

Use cases 1 and 2 should be reachable in one click from the upload step. Use case 3 must stay accessible but does not get equal visual weight.

## Information architecture

Three top-level states, sharing the same single-column layout for A and B and expanding to two columns only after processing.

### State A — empty (no file)

Centered single column. No reserved space for a future preview.

```
                Pecha Printer
        Imprime un PDF en mode pecha à découper

   ┌───────────────────────────────────────────┐
   │                                           │
   │       📄  Glisse un PDF ici               │
   │           ou clique pour parcourir        │
   │                                           │
   └───────────────────────────────────────────┘

   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
   │  Standard    │  │  Standard    │  │  Shechen     │
   │  A4          │  │  A3          │  │  TibetDoc    │
   │              │  │              │  │              │
   │  3 par page  │  │  3 par page  │  │  3 par page  │
   │  Fit page    │  │  Fit page    │  │  crop marks  │
   │  Recto-verso │  │  Recto-verso │  │  Recto-verso │
   │              │  │              │  │  Pour PDF    │
   │              │  │              │  │  TibetDoc ⓘ  │
   └──────────────┘  └──────────────┘  └──────────────┘

              ⚙ Options personnalisées
```

- Title and tagline at top.
- Drop zone: full-width, generous padding, dashed border, click-to-browse + drag-and-drop both supported.
- Three preset cards below: **Standard A4** (selected by default), **Standard A3**, **Shechen TibetDoc**.
- "Options personnalisées" link below the cards — discreet, single line of text, opens the detailed panel when clicked.

### State B — file selected, not yet processed

Identical layout to A, but the drop zone collapses into a file chip and a primary CTA appears.

```
   📄 input.pdf  (1.1 MB)                          ✕

   [ three preset cards — unchanged ]

   ⚙ Options personnalisées

           ┌─────────────────────────────┐
           │   ▶  Imprimer le PDF        │
           └─────────────────────────────┘
```

- File chip shows name + size + dismiss (✕) button.
- ✕ returns to State A (chip fades out, drop zone fades in).
- Dropping a new file onto the chip area replaces the current file.
- Primary CTA appears with a subtle slide-up animation when a file is present.

### State C — after processing

Two-column layout. Left column is a compacted version of B with a Download CTA promoted to primary; right column slides in with the PDF preview.

```
┌──────────────────────┐  ┌────────────────────────────────┐
│ 📄 input.pdf      ✕  │  │                                │
│                      │  │                                │
│ Style: [Standard ✓]  │  │       PDF preview              │
│                      │  │       (embed)                  │
│ ⬇  Télécharger       │  │                                │
│ ↻  Re-traiter        │  │                                │
└──────────────────────┘  └────────────────────────────────┘
```

- Same preset cards remain interactive — changing a preset and clicking "Re-traiter" reprocesses without re-uploading.
- ✕ on the chip returns to State A (preview slides out + form recenters).

## Preset cards

Each card holds:

- Title (e.g. "Standard A4")
- Three concise spec lines describing what the preset does
- For Shechen only: a fourth line "Pour PDF TibetDoc ⓘ" where ⓘ opens a small inline popover showing the TibetDoc export-config image (the same image as the current help modal)

States:

- **Default**: subtle border, neutral fill
- **Hover**: border brightens, slight elevation
- **Selected**: accent border + slightly tinted fill + check indicator

Default selection is **Standard A4**.

If the uploaded PDF is detected to contain crop marks (cheap heuristic — see Implementation notes), the Shechen card gains a small pulsing "Détecté" badge to suggest it, but the selection does **not** change automatically. The user stays in control.

## Custom panel

The "⚙ Options personnalisées" link expands an inline panel directly below the cards (smooth height animation, ~250ms). The panel does not replace the cards — both stay visible, and switching back to a preset card collapses the panel and re-applies the preset values.

Inside the panel, the existing form fields are reorganised into three groups with clear headings:

1. **Papier** — paper size, orientation
2. **Mise en page** — pages per sheet, autoscale, two-sided flip, crop-from-marks
3. **Marges** — the existing four-mode margin widget (None / All / H+V / Custom), preserved as-is

Each group is a visually distinct section (subtle separator or sub-card) so the user can scan rather than wade through a flat form.

When the user manually edits any value inside the panel, the three preset cards above lose their "selected" state — the form is now in a custom configuration, and that's surfaced via a small inline label like "Réglages personnalisés".

## Visual style

**Theme: light by default**, with `@media (prefers-color-scheme: dark)` swapping to a dark palette for users whose OS prefers dark. No in-app toggle.

Rationale: this is a document-handling tool. PDF previews are white; a light surrounding is visually consistent. The user base skews towards conventions of office/print tools (Acrobat, Drive). Auto-switching for dark-mode users covers the modern aesthetic preference without UI clutter.

**Palette (light)**:

- Background: off-white (`#fafaf9` or similar — not pure white, to soften)
- Surface (cards, drop zone): white with 1px subtle border
- Text primary: near-black (`#1a1a1a`)
- Text secondary: warm grey (`#666`)
- Accent: a warm blue (`#3b6fb8` or similar — readable, professional, not "tech bro")
- Selected fill: accent at ~8% opacity
- Success (Download): green (`#2e7d4f`)
- Danger (errors): red (`#c53030`)

**Palette (dark)**: mirrored, with a softened dark background (not pure black) and slightly more vibrant accents.

**Typography**: system stack (`-apple-system, "Inter", "Segoe UI", system-ui, sans-serif`). Sizes one step larger than the current form. Tabular numbers for the numeric inputs in the margin panel.

**Shape / spacing**:

- 12–16px border radius on cards and drop zone
- 8px radius on inputs and small buttons
- Generous whitespace — at least 24px between major sections
- Container max-width around 720–800px in States A and B (centered)

## Animations

Small, purposeful. Nothing decorative for its own sake.

| Trigger | Animation | Timing |
|---|---|---|
| Drag enters drop zone | Border accent + subtle background fill + 1.02× scale | 200ms ease-out |
| File dropped | Drop zone fades out → chip fades+slides in | 300ms total |
| Preset card hover | Border/shadow transition | 150ms |
| Preset card selected | Border + fill cross-fade | 200ms |
| Custom panel toggle | Height animates open/close | 250ms ease-out |
| CTA appears (State B) | Slide up + fade in | 250ms |
| Submit clicked | Button shows spinner, becomes `aria-busy` | — |
| Preview appears (State C) | Slide in from right + fade | 350ms ease-out |
| File ✕ clicked | Chip fades out, drop zone fades in (back to A) | 250ms |

`prefers-reduced-motion: reduce` disables transitions/animations.

## Help / discoverability

The floating `?` button in the bottom-right corner and its modal go away. The Shechen-specific help (TibetDoc export config image) moves to a small inline popover triggered by the ⓘ inside the Shechen card. No other modal aid is needed.

If, after implementation, we discover specific user confusion points, we add tooltips on hover for individual fields inside the Custom panel — but those are not part of this initial overhaul.

## Implementation notes (non-binding for design, included for context)

- **Tech**: Rails ERB views, Pico CSS as base, custom CSS for the new components, Stimulus controllers. No new JS framework or build step.
- **New Stimulus controllers**:
  - `preset_controller` — manages the three preset cards + state of underlying form fields
  - `dropzone_controller` — drag-and-drop + click-to-browse + chip rendering
  - existing `margins_controller` stays unchanged
  - existing `help_controller` is removed
- **Existing form fields**: every current field stays in the DOM (hidden when not in Custom panel, or readonly when a preset is active). The backend contract is unchanged.
- **Crop-marks auto-detection** (optional, nice-to-have): we already have `CropMarkDetector` server-side. A lightweight client-side hint is out of scope; the "Détecté" badge can either (a) be skipped for v1, or (b) be set after first submission if the detector ran successfully. **Decision: skip for v1**, revisit if it adds clear value.
- **State A → C transition**: handled by the existing Rails redirect flow (`create` → `edit`), styled with CSS view transitions or a simple CSS keyframe on page load when the URL has a token.

## What disappears from the current UI

- The floating `?` help button (bottom-right)
- The full help modal
- The always-visible flat list of all options (paper size, orientation, pages per sheet, autoscale, margins) — now collapsed inside the Custom panel
- The separate "Process another PDF" button (replaced by ✕ on the file chip)

## What stays

- The Rails backend, models, controllers, and the existing form contract
- The `margins_controller.js` widget — already good
- The PDF preview embed in State C
- Pico CSS as the base framework

## Success criteria

- First-time user lands on State A and can reach a processed PDF in ≤3 actions: drop file → pick preset → click "Imprimer le PDF".
- The Shechen preset is reachable in 1 click from State A (vs. the current ~3 clicks through the help modal).
- A returning power user can open the Custom panel in 1 click and access every option that exists today.
- Visual appearance is described by the maintainer as "modern but not trendy", "calm", "easy to look at".

## Open items

None blocking implementation. Two soft items to revisit after launch:

- Whether the "Détecté" Shechen-suggestion badge adds enough value to be worth shipping
- Whether per-field tooltips inside the Custom panel improve discoverability
