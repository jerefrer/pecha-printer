// app/javascript/controllers/flash_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { type: String };

  connect() {
    if (this.typeValue === "notice") {
      // Auto-dismiss success messages.
      this.timeout = setTimeout(() => this.dismiss(), 5000);
    } else {
      // Keep errors until dismissed, and make sure they're visible.
      this.element.scrollIntoView({ behavior: "smooth", block: "nearest" });
    }
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout);
  }

  dismiss() {
    if (this.timeout) clearTimeout(this.timeout);
    this.element.style.transition = "opacity 200ms ease, transform 200ms ease";
    this.element.style.opacity = "0";
    this.element.style.transform = "translateY(-8px)";
    setTimeout(() => this.element.remove(), 200);
  }
}
