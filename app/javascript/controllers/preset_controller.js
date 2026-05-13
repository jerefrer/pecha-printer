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
  static values = {
    current: { type: String, default: "standard_a4" },
    persisted: { type: Boolean, default: false },
  };

  connect() {
    this.form = this.element.closest("form");
    if (!this.form) return;
    this.boundFormChange = (e) => this.onFormChange(e);
    this.boundDocumentClick = (e) => this.closeHelpOutside(e);
    this.form.addEventListener("change", this.boundFormChange);
    document.addEventListener("click", this.boundDocumentClick);

    if (this.persistedValue) {
      // State C: form is pre-populated with persisted values. Detect which
      // preset matches them (if any) — don't overwrite.
      const matched = this.detectMatchingPreset();
      this.currentValue = matched || "";
      this.refreshCardStyles();
    } else {
      // State A/B: fresh form. Apply the default preset so all missing
      // defaults (portrait, flip, crop, margins) get filled in.
      this.apply(this.currentValue);
    }
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

  selectKeydown(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      this.select(event);
    }
  }

  apply(name) {
    const preset = PRESETS[name];
    if (!preset) return;
    // Suppress onFormChange while we batch-write all the field values —
    // otherwise the synthetic change events fire in sequence and trip
    // matchesCurrent() before the form has been fully updated.
    this.applying = true;
    this.currentValue = name;
    this.setRadio("pdf[paper_size]", preset.paper_size);
    this.setRadio("pdf[portrait]", preset.portrait);
    this.setRadio("pdf[pages_per_sheet]", preset.pages_per_sheet);
    this.setRadio("pdf[autoscale]", preset.autoscale);
    this.setCheckbox("pdf[two_sided_flipped]", preset.two_sided_flipped === "1");
    this.setCheckbox("pdf[crop_from_marks]", preset.crop_from_marks === "1");
    this.setMarginMode(preset.sheet_margin_mode, preset.sheet_margins);
    this.applying = false;
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
    if (this.applying) return;
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
    const marginMode = this.form.querySelector('.margins-section input[type="radio"]:checked')?.value;
    const margins = this.form.querySelector('input[name="pdf[sheet_margins]"]')?.value;
    return (
      paper === preset.paper_size &&
      portrait === preset.portrait &&
      pps === preset.pages_per_sheet &&
      auto === preset.autoscale &&
      flip === preset.two_sided_flipped &&
      crop === preset.crop_from_marks &&
      marginMode === preset.sheet_margin_mode &&
      margins === preset.sheet_margins
    );
  }

  detectMatchingPreset() {
    return Object.keys(PRESETS).find((name) => {
      const original = this.currentValue;
      this.currentValue = name;
      const ok = this.matchesCurrent();
      this.currentValue = original;
      return ok;
    });
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
