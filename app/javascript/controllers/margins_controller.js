// app/javascript/controllers/margins_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["mode", "inputs", "all", "hv", "custom", "form"];

  connect() {
    this.hiddenInput = this.element.querySelector(
      'input[name="pdf[sheet_margins]"]'
    );
    const marginsValue = this.hiddenInput?.value?.trim() || "0 -5 0 -5";
    this.initializeFromString(marginsValue);
  }

  initializeFromString(margins) {
    // Always split into 4 numbers, defaulting to 0
    const values = this.normalizeValues(margins);
    const [left, bottom, right, top] = values;
    // Determine mode based on patterns
    let mode;
    if (left === 0 && bottom === 0 && right === 0 && top === 0) {
      mode = "none";
    } else if (left === right && bottom === top && left === bottom) {
      // All values are the same and non-zero
      mode = "all";
      this.element.querySelector('[data-target="all"]').value = left;
    } else if (left === right && bottom === top) {
      // Horizontal/vertical pattern
      mode = "horizontal_vertical";
      this.element.querySelector('[data-target="horizontal"]').value = left;
      this.element.querySelector('[data-target="vertical"]').value = bottom;
    } else {
      // Custom values
      mode = "custom";
      this.element.querySelector('[data-target="left"]').value = left;
      this.element.querySelector('[data-target="bottom"]').value = bottom;
      this.element.querySelector('[data-target="right"]').value = right;
      this.element.querySelector('[data-target="top"]').value = top;
    }

    // Set the radio button
    const radio = this.element.querySelector(
      `.margins-section input[type="radio"][value="${mode}"]`
    );
    if (radio) {
      radio.checked = true;
    }

    // Show the appropriate inputs
    this.updateMarginInputs(mode);

    // Always update hidden input with normalized value
    this.updateHiddenInput(values);
  }

  updateMode(event) {
    this.updateMarginInputs(event.target.value);

    // Reset values when mode changes
    const mode = event.target.value;
    let values = [0, 0, 0, 0];

    if (mode === "all") {
      const all = this.element.querySelector('[data-target="all"]').value || 0;
      values = [all, all, all, all];
    } else if (mode === "horizontal_vertical") {
      const h =
        this.element.querySelector('[data-target="horizontal"]').value || 0;
      const v =
        this.element.querySelector('[data-target="vertical"]').value || 0;
      values = [h, v, h, v];
    } else if (mode === "custom") {
      values = [
        this.element.querySelector('[data-target="left"]').value || 0,
        this.element.querySelector('[data-target="bottom"]').value || 0,
        this.element.querySelector('[data-target="right"]').value || 0,
        this.element.querySelector('[data-target="top"]').value || 0,
      ];
    }

    this.updateHiddenInput(values);
  }

  updateMarginInputs(mode) {
    this.inputsTarget.style.display = mode === "none" ? "none" : "block";
    this.allTarget.style.display = mode === "all" ? "block" : "none";
    this.hvTarget.style.display =
      mode === "horizontal_vertical" ? "block" : "none";
    this.customTarget.style.display = mode === "custom" ? "block" : "none";
  }

  updateHiddenInput(values) {
    if (this.hiddenInput) {
      const normalized = values.map((value) =>
        Number.isFinite(Number(value)) ? Number(value) : 0
      );
      this.hiddenInput.value = normalized.join(" ");
    }
  }

  submitForm(event) {
    const modeRadio = this.element.querySelector(".margin-mode-radio:checked");
    const mode = modeRadio ? modeRadio.value : "none";
    let values = [0, 0, 0, 0];

    if (mode === "all") {
      const value =
        this.element.querySelector('[data-target="all"]').value || 0;
      values = [value, value, value, value];
    } else if (mode === "horizontal_vertical") {
      const h =
        this.element.querySelector('[data-target="horizontal"]').value || 0;
      const v =
        this.element.querySelector('[data-target="vertical"]').value || 0;
      values = [h, v, h, v];
    } else if (mode === "custom") {
      values = [
        this.element.querySelector('[data-target="left"]').value || 0,
        this.element.querySelector('[data-target="bottom"]').value || 0,
        this.element.querySelector('[data-target="right"]').value || 0,
        this.element.querySelector('[data-target="top"]').value || 0,
      ];
    }

    this.updateHiddenInput(values);
  }

  normalizeValues(margins) {
    const parts = margins
      .split(" ")
      .filter((part) => part.length > 0)
      .map((part) => Number(part));

    while (parts.length < 4) {
      parts.push(0);
    }

    return parts
      .slice(0, 4)
      .map((value) => (Number.isFinite(value) ? value : 0));
  }
}
