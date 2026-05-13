# Pecha Printer UI Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the flat form with a focused upload-first interface featuring three preset cards (Standard A4 · Standard A3 · Shechen TibetDoc), a collapsible "Personnalisé" panel, and a polished light theme that auto-switches to dark via `prefers-color-scheme`.

**Architecture:** ERB view restructured around three layout states (empty / file-selected / processed). The `:has()` CSS selector drives the State A/B → State C layout switch — no JS class toggle needed. New Stimulus controllers (`dropzone`, `preset`, `custom_panel`) coordinate UI behaviour against the existing Rails form contract — every current form field stays in the DOM, hidden when a preset is active. The existing `margins_controller` is reused unchanged inside the Personnalisé panel.

**Tech Stack:**
- **Rails 7** + ERB (existing)
- **Tailwind CSS** via `tailwindcss-rails` gem — standalone CLI binary, no Node dependency
- **Stimulus** (existing) for behaviour
- **Lucide icons** via `lucide-rails` gem for clean inline SVG icons
- **Pico CSS** is removed

**Spec:** [docs/superpowers/specs/2026-05-13-ui-overhaul-design.md](../specs/2026-05-13-ui-overhaul-design.md)

---

## File structure

**Create:**
- `config/tailwind.config.js` — Tailwind config with custom palette, dark mode = media, keyframes
- `app/assets/stylesheets/application.tailwind.css` — Tailwind layers + custom component classes via `@layer components`
- `app/javascript/controllers/dropzone_controller.js` — drag-and-drop, click-to-browse, chip rendering, ✕ to reset
- `app/javascript/controllers/preset_controller.js` — three-card selection, applies preset values into the underlying form fields, demotes selection when user manually edits
- `app/javascript/controllers/custom_panel_controller.js` — collapse/expand the Personnalisé panel

**Modify:**
- `Gemfile` — add `tailwindcss-rails` and `lucide-rails`
- `Procfile.dev` — created by `tailwindcss:install` to run the watch process alongside Rails
- `app/views/pdfs/new.html.erb` — full restructure (described task by task)
- `app/views/layouts/application.html.erb` — remove Pico CSS, remove `help`/`fade` controllers from `<main>`
- `bin/dev` — created by `tailwindcss:install` to launch `Procfile.dev`

**Delete:**
- `app/assets/stylesheets/application.css` — replaced by `application.tailwind.css`
- `app/assets/stylesheets/components/form.css` — most of it obsolete; the few remaining margin-widget styles move into `application.tailwind.css` under `@layer components`
- `app/javascript/controllers/help_controller.js`

---

## Verification approach

No automated UI tests exist for this project. Each task ends with manual browser verification on `http://localhost:3000/`. Start the dev server with `bin/dev` (added by `tailwindcss:install`); this runs both the Rails server and the tailwindcss CLI watcher concurrently.

Sample PDF for verification: `input.pdf` at the repo root (14 pages, already in working tree).

End-to-end smoke test = upload `input.pdf` from the repo root, click Imprimer, get a downloadable processed PDF that matches the selected preset.

---

## Task 1: Install Tailwind + lucide-rails, configure theme, remove Pico

**Files:**
- Modify: `Gemfile`
- Run installer (creates `config/tailwind.config.js`, `app/assets/stylesheets/application.tailwind.css`, `Procfile.dev`, `bin/dev`)
- Modify: `config/tailwind.config.js`
- Modify: `app/assets/stylesheets/application.tailwind.css`
- Modify: `app/views/layouts/application.html.erb`
- Delete: `app/assets/stylesheets/application.css`, `app/assets/stylesheets/components/form.css`

- [ ] **Step 1: Add the gems**

```bash
bundle add tailwindcss-rails
bundle add lucide-rails
```

- [ ] **Step 2: Run the Tailwind installer**

```bash
bin/rails tailwindcss:install
```

This generates `config/tailwind.config.js`, `app/assets/stylesheets/application.tailwind.css`, `Procfile.dev`, and `bin/dev`. It also updates the layout to load the compiled stylesheet.

- [ ] **Step 3: Replace `config/tailwind.config.js` with our theme**

```javascript
const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  darkMode: "media",
  content: [
    "./app/views/**/*.{erb,html}",
    "./app/javascript/**/*.js",
    "./app/helpers/**/*.rb",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter var", "Inter", ...defaultTheme.fontFamily.sans],
      },
      colors: {
        accent: {
          DEFAULT: "#3b6fb8",
          hover: "#2f5a99",
          soft: "rgba(59, 111, 184, 0.08)",
          ring: "rgba(59, 111, 184, 0.25)",
        },
        success: {
          DEFAULT: "#2e7d4f",
          hover: "#266b42",
        },
        ink: {
          DEFAULT: "#1a1a1a",
          muted: "#6b6b66",
        },
        canvas: {
          DEFAULT: "#fafaf7",
          surface: "#ffffff",
          hover: "#f5f5f1",
          border: "#e6e4dd",
          "border-strong": "#d3d1c8",
        },
        "canvas-dark": {
          DEFAULT: "#16181c",
          surface: "#1f2227",
          hover: "#262a30",
          border: "#2e333a",
          "border-strong": "#3e444c",
          text: "#ececec",
          "text-muted": "#9aa0a8",
          accent: "#6e9bdc",
          "accent-hover": "#87aee6",
        },
      },
      borderRadius: {
        DEFAULT: "10px",
        lg: "14px",
        xl: "18px",
      },
      boxShadow: {
        card: "0 1px 2px rgba(0, 0, 0, 0.04)",
        elevated: "0 4px 12px rgba(0, 0, 0, 0.06)",
        floating: "0 12px 32px rgba(0, 0, 0, 0.08)",
      },
      keyframes: {
        "cta-in": {
          "0%": { opacity: "0", transform: "translateY(8px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        "preview-in": {
          "0%": { opacity: "0", transform: "translateX(24px)" },
          "100%": { opacity: "1", transform: "translateX(0)" },
        },
        "chip-in": {
          "0%": { opacity: "0", transform: "translateY(-4px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        "preset-in": {
          "0%": { opacity: "0", transform: "translateY(6px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        float: {
          "0%, 100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-3px)" },
        },
      },
      animation: {
        "cta-in": "cta-in 250ms cubic-bezier(0.16, 1, 0.3, 1)",
        "preview-in": "preview-in 350ms cubic-bezier(0.16, 1, 0.3, 1)",
        "chip-in": "chip-in 250ms cubic-bezier(0.16, 1, 0.3, 1)",
        "preset-in": "preset-in 250ms cubic-bezier(0.16, 1, 0.3, 1) backwards",
        float: "float 3s ease-in-out infinite",
      },
    },
  },
  plugins: [require("@tailwindcss/forms")],
};
```

Then install the forms plugin:

```bash
# tailwindcss-rails ships the standalone Tailwind binary which bundles forms support;
# if @tailwindcss/forms is missing, drop the plugin line above. Verify with:
bin/rails tailwindcss:build
```

If `tailwindcss:build` errors about `@tailwindcss/forms`, remove the `plugins: [require("@tailwindcss/forms")]` line — the standalone CLI may not include the plugin. We can style native form inputs without it.

- [ ] **Step 4: Replace `app/assets/stylesheets/application.tailwind.css` with our component layer**

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    @apply bg-canvas text-ink antialiased font-sans;
  }
  @media (prefers-color-scheme: dark) {
    body {
      background-color: #16181c;
      color: #ececec;
    }
  }
  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
      animation-duration: 1ms !important;
      transition-duration: 1ms !important;
    }
  }
}

@layer components {
  /* Reusable component classes — used where the same pattern repeats
     and inline utilities would hurt readability. One-offs stay inline. */

  .btn {
    @apply inline-flex items-center justify-center gap-2 px-5 py-3
           font-semibold rounded-lg cursor-pointer
           transition-all duration-150 ease-out select-none;
  }

  .btn-primary {
    @apply btn bg-accent text-white shadow-[0_2px_8px_var(--tw-shadow-color)]
           shadow-accent/30 hover:bg-accent-hover hover:-translate-y-0.5;
  }
  .btn-success { @apply btn bg-success text-white hover:bg-success-hover; }
  .btn-ghost {
    @apply btn bg-canvas-surface text-ink border border-canvas-border-strong
           hover:bg-canvas-hover;
  }

  .card {
    @apply bg-canvas-surface border border-canvas-border rounded-lg
           shadow-card;
  }

  /* Margin widget — kept compatible with margins_controller.js */
  .margins-section input[type="radio"] { @apply hidden; }
  .margins-section input[type="radio"] + label {
    @apply px-3 py-1.5 border border-canvas-border rounded
           cursor-pointer text-sm bg-canvas-surface text-ink
           transition-colors duration-150;
  }
  .margins-section input[type="radio"]:checked + label {
    @apply bg-accent border-accent text-white;
  }

  .margin-custom-grid {
    display: grid;
    grid-template-columns: 1fr auto 1fr;
    align-items: center;
    justify-items: center;
    width: 75%;
    margin: 0 auto;
  }
  .margin-input { @apply w-24 px-2 py-2 text-sm rounded border border-canvas-border bg-canvas-surface text-ink; }
  .margin-custom .margin-input { @apply text-center; }
}

@media (prefers-color-scheme: dark) {
  .card {
    background-color: #1f2227;
    border-color: #2e333a;
  }
  .btn-ghost {
    background-color: #1f2227;
    color: #ececec;
    border-color: #3e444c;
  }
  .margins-section input[type="radio"] + label {
    background-color: #1f2227;
    border-color: #2e333a;
    color: #ececec;
  }
}
```

- [ ] **Step 5: Update `app/views/layouts/application.html.erb`**

Replace the full file with:

```erb
<!DOCTYPE html>
<html>

<head>
  <title><%= content_for(:title) || "Pecha Printer" %></title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>

  <%= yield :head %>

  <link rel="manifest" href="/manifest.json">
  <link rel="icon" href="/favicon.png" type="image/png">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="/favicon.png">
  <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>
</head>

<body>
  <main>
    <%= yield %>
  </main>
</body>

</html>
```

Pico CSS links are gone. `<main>` has no Stimulus controllers attached.

- [ ] **Step 6: Delete the old CSS files**

```bash
git rm app/assets/stylesheets/application.css
git rm app/assets/stylesheets/components/form.css
# components/ directory is now empty; remove it if so:
[ -d app/assets/stylesheets/components ] && [ -z "$(ls -A app/assets/stylesheets/components)" ] && rmdir app/assets/stylesheets/components
```

- [ ] **Step 7: Verify the Tailwind build succeeds and the page loads**

```bash
bin/rails tailwindcss:build
bin/dev
```

Open: `http://localhost:3000/`
Expected: page loads without 404s for stylesheets. The existing form looks unstyled (no Pico, no new styles yet — Task 2 introduces the layout). No console errors.

- [ ] **Step 8: Commit**

```bash
git add Gemfile Gemfile.lock config/tailwind.config.js app/assets/stylesheets/application.tailwind.css app/views/layouts/application.html.erb Procfile.dev bin/dev
git rm --cached app/assets/stylesheets/application.css app/assets/stylesheets/components/form.css 2>/dev/null || true
git add -A
git commit -m "Adopts Tailwind CSS and Lucide icons, removes Pico CSS"
```

---

## Task 2: View skeleton — three-state shell

**Files:**
- Modify: `app/views/pdfs/new.html.erb` (full restructure with placeholders)

- [ ] **Step 1: Replace `app/views/pdfs/new.html.erb` with the skeleton**

```erb
<div class="min-h-screen flex justify-center [.has-preview_&]:justify-start p-6 lg:p-10">
  <div class="flex gap-8 items-start w-full max-w-[760px] [.has-preview_&]:max-w-none">
    <div class="flex flex-col gap-8 w-full [.has-preview_&]:max-w-[380px]">
      <header class="text-center [.has-preview_&]:text-left">
        <h1 class="m-0 text-3xl font-bold tracking-tight [.has-preview_&]:text-xl">Pecha Printer</h1>
        <p class="mt-2 text-ink-muted [.has-preview_&]:hidden">
          Imprime un PDF en mode pecha à découper et à empiler.
        </p>
      </header>

      <%= form_for @pdf, multipart: true,
            html: { class: "flex flex-col gap-6" },
            data: {
              controller: "margins preset dropzone custom-panel",
              action: "submit->margins#submitForm"
            } do |form| %>

        <%= form.hidden_field :sheet_margins, data: { margins_target: "form" } %>

        <%# Drop zone — Task 3 %>
        <div data-component="dropzone-placeholder" class="card p-8 text-center text-ink-muted">[drop zone placeholder]</div>

        <%# Preset cards — Task 4 %>
        <div data-component="presets-placeholder" class="card p-8 text-center text-ink-muted">[preset cards placeholder]</div>

        <%# Custom panel — Task 5 %>
        <div data-component="custom-placeholder" class="text-center text-ink-muted text-sm">[custom panel placeholder]</div>

        <%# CTA — Task 6 %>
        <div data-component="cta-placeholder" class="card p-4 text-center text-ink-muted">[CTA placeholder]</div>

      <% end %>
    </div>

    <% if @pdf.persisted? %>
      <div class="flex-1 min-w-0 h-[calc(100vh-5rem)] min-h-[600px] rounded-lg border border-canvas-border bg-canvas-surface shadow-card overflow-hidden animate-preview-in">
        <embed src="<%= download_pdf_path(@pdf) %>#toolbar=0"
               type="application/pdf"
               class="block w-full h-full border-0" />
      </div>
    <% end %>
  </div>
</div>

<%# When a preview exists, signal it to the outer container via a body class
    so the [.has-preview_&]:* utilities in the layout activate. %>
<% if @pdf.persisted? %>
  <script>document.body.classList.add("has-preview");</script>
<% end %>
```

**Why the body class instead of `:has(...)`:** the preview pane is a sibling of the form container, and applying `:has()` from the outer wrapper to a deep descendant of itself is verbose and brittle to refactor. A one-line body class is simpler, supports IE-era browsers, and is trivial to reason about. The CSS-only refactor can be revisited later if desired.

- [ ] **Step 2: Verify in browser**

Open: `http://localhost:3000/`
Manual checks:
- Centered shell with "Pecha Printer" title (bold, large), tagline, and four labelled placeholders
- No floating ? button anywhere on the page
- No console errors

- [ ] **Step 3: Commit**

```bash
git add app/views/pdfs/new.html.erb
git commit -m "Restructures view shell around three-state layout"
```

---

## Task 3: Drop zone — HTML, JS controller

**Files:**
- Create: `app/javascript/controllers/dropzone_controller.js`
- Modify: `app/views/pdfs/new.html.erb`

- [ ] **Step 1: Create `app/javascript/controllers/dropzone_controller.js`**

```javascript
import { Controller } from "@hotwired/stimulus";

// Renders either a drop zone (no file) or a file chip (file selected).
// Reuses the existing `<input type="file" name="pdf[file]">` element produced
// by `form.file_field :file` — we just relocate it and swap the visible UI.
export default class extends Controller {
  static targets = ["dropzone", "chip", "chipName", "chipSize", "fileInput"];

  connect() {
    if (!this.hasFileInputTarget) return;
    this.fileInputTarget.addEventListener("change", () => this.renderForState());
    this.element.addEventListener("dragover", (e) => this.dragOver(e));
    this.element.addEventListener("dragleave", (e) => this.dragLeave(e));
    this.element.addEventListener("drop", (e) => this.drop(e));
    this.renderForState();
  }

  dragOver(event) {
    event.preventDefault();
    if (this.hasDropzoneTarget) this.dropzoneTarget.classList.add("is-dragover");
  }

  dragLeave(event) {
    if (event.target === this.dropzoneTarget) {
      this.dropzoneTarget.classList.remove("is-dragover");
    }
  }

  drop(event) {
    event.preventDefault();
    if (this.hasDropzoneTarget) this.dropzoneTarget.classList.remove("is-dragover");
    const file = event.dataTransfer?.files?.[0];
    if (!file || file.type !== "application/pdf") return;
    const dt = new DataTransfer();
    dt.items.add(file);
    this.fileInputTarget.files = dt.files;
    this.renderForState();
  }

  remove(event) {
    event.preventDefault();
    this.fileInputTarget.value = "";
    this.renderForState();
  }

  renderForState() {
    const file = this.fileInputTarget.files?.[0];
    if (file) {
      if (this.hasDropzoneTarget) this.dropzoneTarget.hidden = true;
      if (this.hasChipTarget) {
        this.chipTarget.hidden = false;
        this.chipNameTarget.textContent = file.name;
        this.chipSizeTarget.textContent = this.formatSize(file.size);
      }
    } else {
      if (this.hasDropzoneTarget) this.dropzoneTarget.hidden = false;
      if (this.hasChipTarget) this.chipTarget.hidden = true;
    }
  }

  formatSize(bytes) {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }
}
```

- [ ] **Step 2: Replace the drop-zone placeholder in `app/views/pdfs/new.html.erb`**

Locate the line `<div data-component="dropzone-placeholder" ...>[drop zone placeholder]</div>` and replace it with:

```erb
<% if @pdf.persisted? %>
  <div class="card flex items-center gap-3 px-4 py-3 animate-chip-in">
    <%= lucide_icon "file-text", class: "w-5 h-5 text-accent shrink-0" %>
    <span class="flex-1 font-semibold break-all"><%= @pdf.file.filename %></span>
    <%= link_to new_pdf_path,
          class: "w-8 h-8 inline-flex items-center justify-center rounded text-ink-muted hover:text-red-600 hover:bg-canvas-hover transition-colors",
          aria: { label: "Choisir un autre fichier" } do %>
      <%= lucide_icon "x", class: "w-4 h-4" %>
    <% end %>
  </div>
<% else %>
  <div data-dropzone-target="dropzone"
       class="card relative flex flex-col items-center justify-center gap-3 p-10 cursor-pointer border-2 border-dashed border-canvas-border-strong hover:border-accent transition-colors duration-200 [&.is-dragover]:border-accent [&.is-dragover]:bg-accent-soft [&.is-dragover]:scale-[1.01]">
    <%= lucide_icon "upload-cloud", class: "w-12 h-12 text-ink-muted animate-float" %>
    <div class="text-lg font-semibold">Glisse un PDF ici</div>
    <div class="text-sm text-ink-muted">ou clique pour parcourir</div>
    <%= form.file_field :file,
          accept: "application/pdf",
          class: "absolute inset-0 opacity-0 cursor-pointer",
          data: { dropzone_target: "fileInput" } %>
  </div>

  <div class="card flex items-center gap-3 px-4 py-3 animate-chip-in"
       data-dropzone-target="chip" hidden>
    <%= lucide_icon "file-text", class: "w-5 h-5 text-accent shrink-0" %>
    <span class="flex-1 font-semibold break-all" data-dropzone-target="chipName"></span>
    <span class="text-sm text-ink-muted shrink-0" data-dropzone-target="chipSize"></span>
    <button type="button"
            class="w-8 h-8 inline-flex items-center justify-center rounded text-ink-muted hover:text-red-600 hover:bg-canvas-hover transition-colors"
            data-action="click->dropzone#remove"
            aria-label="Retirer le fichier">
      <%= lucide_icon "x", class: "w-4 h-4" %>
    </button>
  </div>
<% end %>
```

- [ ] **Step 3: Verify in browser**

Open: `http://localhost:3000/`
Manual checks:
- Drop zone visible: a dashed-border card with a floating cloud-upload icon, "Glisse un PDF ici", "ou clique pour parcourir"
- Hovering shows the border turn accent blue
- Clicking opens the file picker; selecting a PDF replaces the drop zone with the file chip (filename + size + ✕)
- Dragging `input.pdf` from a Finder window onto the drop zone: border highlights, then drop replaces the file
- Clicking ✕ on the chip restores the drop zone

- [ ] **Step 4: Commit**

```bash
git add app/javascript/controllers/dropzone_controller.js app/views/pdfs/new.html.erb
git commit -m "Adds drop zone and file chip with drag-and-drop"
```

---

## Task 4: Preset cards with inline Shechen popover

**Files:**
- Create: `app/javascript/controllers/preset_controller.js`
- Modify: `app/views/pdfs/new.html.erb`

- [ ] **Step 1: Create `app/javascript/controllers/preset_controller.js`**

```javascript
import { Controller } from "@hotwired/stimulus";

// Coordinates the three preset cards with the underlying Rails form fields.
// Each preset applies a set of field values; if the user later edits a field
// manually (via the Personnalisé panel), the cards lose their selected state.
const PRESETS = {
  standard_a4: {
    paper_size: "A4",
    portrait: "false",
    pages_per_sheet: "3",
    autoscale: "pdfjam",
    two_sided_flipped: "1",
    crop_from_marks: "0",
    sheet_margin_mode: "horizontal_vertical",
    sheet_margins: "0 -5 0 -5",
  },
  standard_a3: {
    paper_size: "A3",
    portrait: "false",
    pages_per_sheet: "3",
    autoscale: "pdfjam",
    two_sided_flipped: "1",
    crop_from_marks: "0",
    sheet_margin_mode: "horizontal_vertical",
    sheet_margins: "0 -5 0 -5",
  },
  shechen: {
    paper_size: "A3",
    portrait: "false",
    pages_per_sheet: "3",
    autoscale: "none",
    two_sided_flipped: "1",
    crop_from_marks: "1",
    sheet_margin_mode: "none",
    sheet_margins: "0 0 0 0",
  },
};

export default class extends Controller {
  static targets = ["card", "popover"];
  static values = { current: { type: String, default: "standard_a4" } };

  connect() {
    this.form = this.element.closest("form");
    this.apply(this.currentValue);
    this.boundFormChange = (e) => this.onFormChange(e);
    this.boundDocumentClick = (e) => this.closeHelpOutside(e);
    this.form.addEventListener("change", this.boundFormChange);
    document.addEventListener("click", this.boundDocumentClick);
  }

  disconnect() {
    this.form.removeEventListener("change", this.boundFormChange);
    document.removeEventListener("click", this.boundDocumentClick);
  }

  select(event) {
    const card = event.currentTarget;
    const name = card.dataset.presetName;
    this.currentValue = name;
    this.apply(name);
  }

  apply(name) {
    const preset = PRESETS[name];
    if (!preset) return;
    this.setRadio("pdf[paper_size]", preset.paper_size);
    this.setRadio("pdf[portrait]", preset.portrait);
    this.setRadio("pdf[pages_per_sheet]", preset.pages_per_sheet);
    this.setRadio("pdf[autoscale]", preset.autoscale);
    this.setCheckbox("pdf[two_sided_flipped]", preset.two_sided_flipped === "1");
    this.setCheckbox("pdf[crop_from_marks]", preset.crop_from_marks === "1");
    this.setMarginMode(preset.sheet_margin_mode, preset.sheet_margins);
    this.refreshCardStyles();
  }

  refreshCardStyles() {
    this.cardTargets.forEach((card) => {
      card.classList.toggle("is-selected", card.dataset.presetName === this.currentValue);
    });
  }

  setRadio(name, value) {
    const radio = this.form.querySelector(`input[type="radio"][name="${name}"][value="${value}"]`);
    if (radio) {
      radio.checked = true;
      radio.dispatchEvent(new Event("change", { bubbles: true }));
    }
  }

  setCheckbox(name, checked) {
    const box = this.form.querySelector(`input[type="checkbox"][name="${name}"]`);
    if (box) {
      box.checked = checked;
      box.dispatchEvent(new Event("change", { bubbles: true }));
    }
  }

  setMarginMode(mode, marginString) {
    const radio = this.form.querySelector(
      `.margins-section input[type="radio"][value="${mode}"]`
    );
    if (radio) {
      radio.checked = true;
      radio.dispatchEvent(new Event("change", { bubbles: true }));
    }
    const hidden = this.form.querySelector('input[name="pdf[sheet_margins]"]');
    if (hidden) hidden.value = marginString;
  }

  onFormChange(event) {
    if (event.target.closest(".preset")) return;
    if (event.target.closest('input[type="file"]')) return;
    if (!this.matchesCurrent()) {
      this.currentValue = "";
      this.refreshCardStyles();
    }
  }

  matchesCurrent() {
    const preset = PRESETS[this.currentValue];
    if (!preset) return false;
    const paper = this.form.querySelector('input[name="pdf[paper_size]"]:checked')?.value;
    const portrait = this.form.querySelector('input[name="pdf[portrait]"]:checked')?.value;
    const pps = this.form.querySelector('input[name="pdf[pages_per_sheet]"]:checked')?.value;
    const auto = this.form.querySelector('input[name="pdf[autoscale]"]:checked')?.value;
    const flip = this.form.querySelector('input[name="pdf[two_sided_flipped]"]')?.checked ? "1" : "0";
    const crop = this.form.querySelector('input[name="pdf[crop_from_marks]"]')?.checked ? "1" : "0";
    return (
      paper === preset.paper_size &&
      portrait === preset.portrait &&
      pps === preset.pages_per_sheet &&
      auto === preset.autoscale &&
      flip === preset.two_sided_flipped &&
      crop === preset.crop_from_marks
    );
  }

  toggleHelp(event) {
    event.preventDefault();
    event.stopPropagation();
    if (!this.hasPopoverTarget) return;
    this.popoverTarget.hidden = !this.popoverTarget.hidden;
  }

  closeHelpOutside(event) {
    if (!this.hasPopoverTarget || this.popoverTarget.hidden) return;
    if (this.popoverTarget.contains(event.target)) return;
    if (event.target.closest('[data-action*="toggleHelp"]')) return;
    this.popoverTarget.hidden = true;
  }
}
```

- [ ] **Step 2: Replace the presets placeholder in `app/views/pdfs/new.html.erb`**

```erb
<div class="text-center text-sm text-ink-muted">Choisis un style</div>
<div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
  <% [
    { name: "standard_a4", title: "Standard A4", specs: ["3 pages par feuille", "Ajuste au papier", "Recto-verso"] },
    { name: "standard_a3", title: "Standard A3", specs: ["3 pages par feuille", "Ajuste au papier", "Recto-verso"] },
    { name: "shechen", title: "Shechen TibetDoc", specs: ["3 pages par feuille", "Marques de coupe", "Recto-verso, A3"] }
  ].each_with_index do |p, idx| %>
    <button type="button"
            class="preset card relative flex flex-col gap-2 p-5 text-left cursor-pointer transition-all duration-150 hover:-translate-y-px hover:shadow-card hover:border-canvas-border-strong [&.is-selected]:border-accent [&.is-selected]:bg-accent-soft [&.is-selected]:ring-2 [&.is-selected]:ring-accent-ring animate-preset-in"
            style="animation-delay: <%= 50 * (idx + 1) %>ms;"
            data-preset-name="<%= p[:name] %>"
            data-preset-target="card"
            data-action="click->preset#select">
      <span class="text-base font-bold"><%= p[:title] %></span>
      <ul class="m-0 p-0 list-none text-sm text-ink-muted flex flex-col gap-0.5">
        <% p[:specs].each do |s| %><li><%= s %></li><% end %>
      </ul>
      <% if p[:name] == "shechen" %>
        <span class="mt-auto pt-3 text-xs text-ink-muted inline-flex items-center gap-1">
          Pour PDF TibetDoc ·
          <button type="button"
                  class="text-accent underline bg-transparent border-0 p-0 cursor-pointer text-xs"
                  data-action="click->preset#toggleHelp">voir l'export config</button>
        </span>
        <div class="absolute bottom-[calc(100%+8px)] left-1/2 -translate-x-1/2 w-[min(360px,92vw)] z-10 card p-4 shadow-floating text-left"
             data-preset-target="popover" hidden>
          <h4 class="m-0 mb-2 text-sm font-semibold">Export TibetDoc pour Shechen</h4>
          <p class="m-0 mb-2 text-[13px] leading-snug">
            Dans TibetDoc, exporte ton pecha en <strong>Legal</strong>, coche <em>Show crop marks</em>, mets <em>Distance between crops</em> à <strong>3.35</strong>, et laisse <em>Two pecha sides per print page</em> décoché.
          </p>
          <%= image_tag "tibetdoc-shechen-config.png",
                alt: "TibetDoc export options for Shechen-style pecha",
                class: "w-full rounded border border-canvas-border" %>
        </div>
      <% end %>
    </button>
  <% end %>
</div>
```

- [ ] **Step 3: Verify in browser**

Open: `http://localhost:3000/`
Manual checks:
- Three preset cards in a row (stacked on narrow viewports): Standard A4 (selected, accent border + soft fill + ring), Standard A3, Shechen TibetDoc
- Each card stagger-fades in on page load
- Clicking each card moves the selected highlight
- Clicking "voir l'export config" on the Shechen card opens an inline popover above the card with the TibetDoc image. Clicking outside closes it.
- Opening the Personnalisé panel (Task 5 once done) and changing values clears the selection

- [ ] **Step 4: Commit**

```bash
git add app/javascript/controllers/preset_controller.js app/views/pdfs/new.html.erb
git commit -m "Adds three preset cards with Shechen inline popover"
```

---

## Task 5: Custom panel with reorganised form fields

**Files:**
- Create: `app/javascript/controllers/custom_panel_controller.js`
- Modify: `app/views/pdfs/new.html.erb`

- [ ] **Step 1: Create `app/javascript/controllers/custom_panel_controller.js`**

```javascript
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["panel", "toggle", "chevron"];

  toggle(event) {
    event?.preventDefault();
    const open = this.panelTarget.classList.toggle("is-open");
    this.toggleTarget.setAttribute("aria-expanded", open ? "true" : "false");
    if (this.hasChevronTarget) {
      this.chevronTarget.classList.toggle("rotate-180", open);
    }
  }
}
```

- [ ] **Step 2: Replace the custom-panel placeholder in `app/views/pdfs/new.html.erb`**

```erb
<div class="flex justify-center">
  <button type="button"
          class="inline-flex items-center gap-2 px-3 py-2 rounded text-sm text-ink-muted hover:text-ink hover:bg-canvas-hover transition-colors"
          aria-expanded="false"
          data-custom-panel-target="toggle"
          data-action="click->custom-panel#toggle">
    <%= lucide_icon "sliders-horizontal", class: "w-4 h-4" %>
    <span>Options personnalisées</span>
    <%= lucide_icon "chevron-down", class: "w-4 h-4 transition-transform duration-200", data: { custom_panel_target: "chevron" } %>
  </button>
</div>

<div class="overflow-hidden max-h-0 transition-[max-height] duration-300 ease-out [&.is-open]:max-h-[2000px]"
     data-custom-panel-target="panel">
  <div class="card p-6 flex flex-col gap-6">

    <%# Group: Papier %>
    <section>
      <h3 class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-3">Papier</h3>
      <div class="flex flex-col gap-4">
        <div>
          <div class="text-sm text-ink-muted mb-2">Taille</div>
          <div class="flex flex-wrap gap-1 segmented">
            <%= form.radio_button :paper_size, 'A4', id: "pdf_paper_size_a4" %>
            <%= form.label :paper_size_a4, 'A4' %>
            <%= form.radio_button :paper_size, 'A3', id: "pdf_paper_size_a3" %>
            <%= form.label :paper_size_a3, 'A3' %>
          </div>
        </div>
        <div>
          <div class="text-sm text-ink-muted mb-2">Orientation</div>
          <div class="flex flex-wrap gap-1 segmented">
            <%= form.radio_button :portrait, false, id: "pdf_portrait_no" %>
            <%= form.label :portrait_no, 'Paysage' %>
            <%= form.radio_button :portrait, true, id: "pdf_portrait_yes" %>
            <%= form.label :portrait_yes, 'Portrait' %>
          </div>
        </div>
      </div>
    </section>

    <%# Group: Mise en page %>
    <section>
      <h3 class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-3">Mise en page</h3>
      <div class="flex flex-col gap-4">
        <div>
          <div class="text-sm text-ink-muted mb-2">Pages par feuille</div>
          <div class="flex flex-wrap gap-1 segmented">
            <% %w[2 3 4 5 6 7 8].each do |n| %>
              <%= form.radio_button :pages_per_sheet, n, id: "pdf_pages_per_sheet_#{n}" %>
              <%= form.label "pages_per_sheet_#{n}".to_sym, n %>
            <% end %>
          </div>
        </div>
        <div>
          <div class="text-sm text-ink-muted mb-2">Autoscale</div>
          <div class="flex flex-wrap gap-1 segmented">
            <%= form.radio_button :autoscale, 'none', id: "pdf_autoscale_none" %>
            <%= form.label :autoscale_none, 'Aucun' %>
            <%= form.radio_button :autoscale, 'pdfjam', id: "pdf_autoscale_pdfjam" %>
            <%= form.label :autoscale_pdfjam, 'Ajuste au papier' %>
            <%= form.radio_button :autoscale, 'podofo', id: "pdf_autoscale_podofo" %>
            <%= form.label :autoscale_podofo, 'Recadre sur contenu' %>
          </div>
        </div>
        <label class="inline-flex items-center gap-2 text-sm cursor-pointer">
          <%= form.check_box :two_sided_flipped, { id: 'pdf_two_sided_flipped', class: 'w-[18px] h-[18px] accent-accent' }, '1', '0' %>
          <span>Retourner les pages paires (impression recto-verso)</span>
        </label>
        <label class="inline-flex items-center gap-2 text-sm cursor-pointer">
          <%= form.check_box :crop_from_marks, { id: 'pdf_crop_from_marks', class: 'w-[18px] h-[18px] accent-accent' }, '1', '0' %>
          <span>Le PDF contient des marques de coupe (auto-recadrage)</span>
        </label>
      </div>
    </section>

    <%# Group: Marges %>
    <section class="margins-section">
      <h3 class="text-xs font-semibold uppercase tracking-wider text-ink-muted mb-3">Marges (mm)</h3>
      <div class="flex flex-wrap gap-1 mb-3">
        <%= form.radio_button :sheet_margin_mode, 'none', class: 'margin-mode-radio', id: 'pdf_sheet_margin_mode_none', data: { action: "change->margins#updateMode", margins_target: "mode" } %>
        <%= form.label :sheet_margin_mode_none, 'Aucune' %>
        <%= form.radio_button :sheet_margin_mode, 'all', class: 'margin-mode-radio', id: 'pdf_sheet_margin_mode_all', data: { action: "change->margins#updateMode", margins_target: "mode" } %>
        <%= form.label :sheet_margin_mode_all, 'Toutes' %>
        <%= form.radio_button :sheet_margin_mode, 'horizontal_vertical', checked: true, class: 'margin-mode-radio', id: 'pdf_sheet_margin_mode_horizontal_vertical', data: { action: "change->margins#updateMode", margins_target: "mode" } %>
        <%= form.label :sheet_margin_mode_horizontal_vertical, 'Horizontal/Vertical' %>
        <%= form.radio_button :sheet_margin_mode, 'custom', class: 'margin-mode-radio', id: 'pdf_sheet_margin_mode_custom', data: { action: "change->margins#updateMode", margins_target: "mode" } %>
        <%= form.label :sheet_margin_mode_custom, 'Personnalisées' %>
      </div>

      <div class="mt-2" data-margins-target="inputs">
        <small class="block text-center text-xs text-ink-muted mb-3">Positif = ajoute des marges. Négatif = recadre.</small>
        <div data-margins-target="all">
          <%= form.label :sheet_margin_all, 'Marge sur les 4 côtés', class: "block text-sm text-ink-muted mb-1" %>
          <%= form.number_field :sheet_margin_all, step: 'any', placeholder: '0mm', class: 'margin-input', data: { target: 'all' } %>
        </div>
        <div data-margins-target="hv">
          <div class="flex gap-6">
            <div>
              <%= form.label :sheet_margin_horizontal, 'Gauche & droite', class: "block text-sm text-ink-muted mb-1" %>
              <%= form.number_field :sheet_margin_horizontal, step: 'any', placeholder: '0mm', value: 0, class: 'margin-input', data: { target: 'horizontal' } %>
            </div>
            <div>
              <%= form.label :sheet_margin_vertical, 'Haut & bas', class: "block text-sm text-ink-muted mb-1" %>
              <%= form.number_field :sheet_margin_vertical, step: 'any', placeholder: '0mm', value: -5, class: 'margin-input', data: { target: 'vertical' } %>
            </div>
          </div>
        </div>
        <div data-margins-target="custom">
          <div class="margin-custom-grid">
            <div></div>
            <%= form.number_field :sheet_margin_top, step: 'any', placeholder: '0mm', class: 'margin-input', data: { target: 'top' } %>
            <div></div>
            <%= form.number_field :sheet_margin_left, step: 'any', placeholder: '0mm', class: 'margin-input', data: { target: 'left' } %>
            <div></div>
            <%= form.number_field :sheet_margin_right, step: 'any', placeholder: '0mm', class: 'margin-input', data: { target: 'right' } %>
            <div></div>
            <%= form.number_field :sheet_margin_bottom, step: 'any', placeholder: '0mm', class: 'margin-input', data: { target: 'bottom' } %>
            <div></div>
          </div>
        </div>
      </div>
    </section>

  </div>
</div>
```

- [ ] **Step 3: Verify in browser**

Open: `http://localhost:3000/`
Manual checks:
- "Options personnalisées" link visible with a slider icon and a chevron, closed by default
- Clicking expands a card with three sections: Papier, Mise en page, Marges. Chevron rotates 180°.
- Clicking again collapses with a smooth height transition.
- Segmented controls (paper size, orientation, pages per sheet, autoscale, margin mode) toggle the underlying radios; checkboxes toggle; the margin widget switches between modes (None / Toutes / H/V / Personnalisées) and shows the right inputs.
- Clicking a preset card while the panel is open updates the selected segments accordingly.
- Editing a segmented control manually clears the selected preset card.

- [ ] **Step 4: Commit**

```bash
git add app/javascript/controllers/custom_panel_controller.js app/views/pdfs/new.html.erb
git commit -m "Adds collapsible Personnalisé panel with reorganised form fields"
```

---

## Task 6: Primary CTA and download/re-process actions

**Files:**
- Modify: `app/views/pdfs/new.html.erb`

- [ ] **Step 1: Replace the CTA placeholder in `app/views/pdfs/new.html.erb`**

```erb
<% if @pdf.persisted? %>
  <div class="flex flex-col gap-3 animate-cta-in">
    <%= link_to download_pdf_path(@pdf),
          download: true,
          class: "btn-success no-underline" do %>
      <%= lucide_icon "download", class: "w-5 h-5" %>
      Télécharger le PDF
    <% end %>
    <%= form.submit "↻ Re-traiter avec ces options", class: "btn-ghost" %>
  </div>
<% else %>
  <div class="flex flex-col gap-3 animate-cta-in">
    <button type="submit" class="btn-primary">
      <%= lucide_icon "printer", class: "w-5 h-5" %>
      Imprimer le PDF
    </button>
  </div>
<% end %>
```

- [ ] **Step 2: Verify in browser**

Open: `http://localhost:3000/`
Manual checks:
- Before upload: a large accent-blue "Imprimer le PDF" button with a printer icon, slide-up entry animation
- Hovering the CTA: it lifts 1px and brightens
- After dropping `input.pdf` and submitting: the form posts; on reload State C shows a green "Télécharger le PDF" button (download icon, downloads on click) and a grey "Re-traiter avec ces options" button
- Clicking "Re-traiter avec ces options" after switching to Shechen card reprocesses the PDF in Shechen mode

- [ ] **Step 3: Commit**

```bash
git add app/views/pdfs/new.html.erb
git commit -m "Adds primary CTA stack with download and re-process actions"
```

---

## Task 7: State C polish — two-column layout already wired in Task 2

This task verifies the two-column State C layout introduced via the `has-preview` body class in Task 2. Almost everything is already in place; this task tightens spacing and behaviour.

**Files:**
- (Possibly) Modify: `app/assets/stylesheets/application.tailwind.css`

- [ ] **Step 1: Verify the State C layout works end-to-end**

Open: `http://localhost:3000/`
Steps:
1. Drop `input.pdf`
2. Click "Imprimer le PDF"
3. Page reloads with the preview visible

Manual checks:
- Layout switches from centered single column to two-column (form left ~380px wide, preview right fills the rest)
- The title shrinks and the tagline hides (via `[.has-preview_&]:hidden` utility)
- The preview slides in from the right (animate-preview-in)
- Resize the window to <900px wide: the preview should still be usable; if it overlaps the form badly, fix in Step 2

- [ ] **Step 2 (only if needed): Add a responsive stack for narrow viewports**

If at narrow widths the two-column layout is cramped, add this rule to `application.tailwind.css` under `@layer components`:

```css
@media (max-width: 900px) {
  body.has-preview .has-preview-stack {
    flex-direction: column;
  }
  body.has-preview .has-preview-stack > div {
    max-width: none;
  }
}
```

And add `has-preview-stack` to the inner flex container in `app/views/pdfs/new.html.erb` (the `<div class="flex gap-8 items-start ...">`). If the default Tailwind responsive utilities suffice, skip this step.

- [ ] **Step 3: Commit if changes were made**

```bash
git status
# If clean: skip.
git add -A
git commit -m "Polishes State C responsive behaviour"
```

---

## Task 8: Remove the help controller and legacy assets

**Files:**
- Delete: `app/javascript/controllers/help_controller.js`

- [ ] **Step 1: Delete the help controller**

```bash
git rm app/javascript/controllers/help_controller.js
```

- [ ] **Step 2: Confirm `new.html.erb` has no leftover references to `#help-modal` or `help-button`**

```bash
grep -nE "help-(button|modal|controller)" app/views/pdfs/new.html.erb app/views/layouts/application.html.erb
```

Expected: no output. If anything matches, remove the lines.

- [ ] **Step 3: Verify the browser console is clean**

Open `http://localhost:3000/`, reload, drop a file, switch presets, open Personnalisé, submit, look at the browser DevTools console. Expected: zero errors and zero warnings about missing Stimulus controllers.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "Removes legacy help modal controller"
```

---

## Task 9: End-to-end smoke test

**Files:** (none modified unless issues are found)

- [ ] **Step 1: Full flow — Standard A4 default**

Open: `http://localhost:3000/`
Steps:
1. Drop `input.pdf` (drag from Finder or click and pick from repo root)
2. Confirm Standard A4 stays selected
3. Click "Imprimer le PDF"
4. After the redirect: confirm the file chip shows `input.pdf` and Standard A4 is still selected
5. Confirm the PDF preview on the right shows processed pages
6. Click "Télécharger le PDF" — a file downloads with name ending in `___FOR_PRINTING_ON_A4.pdf`

- [ ] **Step 2: Full flow — Standard A3 swap**

From State C of Step 1:
1. Click the Standard A3 card
2. Click "Re-traiter avec ces options"
3. The preview reloads; download the file and confirm it's A3-sized

- [ ] **Step 3: Full flow — Shechen on the same file**

From any State C:
1. Click the Shechen TibetDoc card
2. Click "Re-traiter avec ces options"
3. (The current `input.pdf` happens to fail crop-mark detection — this is a separate pre-existing bug, not regressed by this change. If the server returns an error flash, that's acceptable for this verification.)

- [ ] **Step 4: Custom panel flow**

From State A:
1. Click "Options personnalisées"
2. Change Pages par feuille to 5, Orientation to Portrait
3. Confirm the three preset cards lose their selected highlight
4. Drop a PDF, click Imprimer
5. Confirm the resulting PDF reflects 5-up portrait

- [ ] **Step 5: Replace-file flow**

In State C:
1. Click the ✕ on the file chip → navigates back to a fresh State A

- [ ] **Step 6: Visual & accessibility sanity pass**

- Resize from 1400px down to 320px width — layout adapts, nothing overflows horizontally
- Toggle OS to dark mode (System Preferences → Appearance) and reload → palette flips and contrast stays readable
- Toggle "Reduce motion" → animations near-instant
- Tab through the form with the keyboard: drop zone, preset cards, custom toggle, submit button are reachable; popover ⓘ button is reachable

- [ ] **Step 7: If issues are found, fix them in the smallest possible patch and commit each fix separately**

For each issue:
- Reproduce it in the browser
- Make the minimal CSS/HTML/JS fix
- Verify
- `git commit -m "<short description>"`

- [ ] **Step 8: Final commit if any uncommitted changes remain**

```bash
git status
# If clean: nothing to do.
# Otherwise:
git add -A
git commit -m "Final UI polish from smoke test"
```

---

## Done

After Task 9 the implementation matches the spec. The UI is Tailwind-styled, light-by-default with auto dark, presets are one click away on the upload screen, the Shechen help lives inline on its own card, and the legacy help modal is gone. The backend contract is unchanged — every existing form field still submits identically.
