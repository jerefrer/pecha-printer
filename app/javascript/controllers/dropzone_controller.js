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
