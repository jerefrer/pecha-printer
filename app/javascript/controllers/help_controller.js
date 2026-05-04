import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    this.dialog = document.getElementById("help-modal")
    this.boundBackdropClose = this.backdropClose.bind(this)
  }

  open(event) {
    event?.preventDefault()
    if (!this.dialog) return
    if (typeof this.dialog.showModal === "function") {
      this.dialog.showModal()
    } else {
      this.dialog.setAttribute("open", "")
    }
    this.dialog.addEventListener("click", this.boundBackdropClose)
  }

  close(event) {
    event?.preventDefault()
    if (!this.dialog) return
    if (typeof this.dialog.close === "function") {
      this.dialog.close()
    } else {
      this.dialog.removeAttribute("open")
    }
    this.dialog.removeEventListener("click", this.boundBackdropClose)
  }

  backdropClose(event) {
    if (event.target === this.dialog) this.close(event)
  }

  applyShechen(event) {
    event?.preventDefault()
    this.checkRadio("pdf_paper_size_a3")
    this.checkRadio("pdf_portrait_no")
    this.checkRadio("pdf_autoscale_none")
    this.checkRadio("pdf_sheet_margin_mode_none")
    this.setCheckbox("pdf_crop_from_marks", true)
    this.close(event)
  }

  checkRadio(id) {
    const el = document.getElementById(id)
    if (!el) return
    el.checked = true
    el.dispatchEvent(new Event("change", { bubbles: true }))
  }

  setCheckbox(id, value) {
    const el = document.getElementById(id)
    if (!el) return
    el.checked = !!value
    el.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
