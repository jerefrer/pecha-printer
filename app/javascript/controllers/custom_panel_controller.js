import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["panel", "toggle", "chevron"];

  toggle(event) {
    event?.preventDefault();
    const open = this.panelTarget.classList.toggle("is-open");
    this.panelTarget.setAttribute("aria-hidden", open ? "false" : "true");
    this.toggleTarget.setAttribute("aria-expanded", open ? "true" : "false");
    if (this.hasChevronTarget) {
      this.chevronTarget.classList.toggle("rotate-180", open);
    }
  }
}
