// app/javascript/controllers/borders_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "mode", "inputs", "all", "hv", "custom", "form" ]

  connect() {
    const bordersInput = this.element.querySelector('input[name="pdf[borders]"]')
    const bordersValue = bordersInput?.value || "0 0 0 0"
    this.initializeFromBorders(bordersValue)
  }

  initializeFromBorders(borders) {
    // Always split into 4 numbers, defaulting to 0
    const values = borders.split(' ').map(Number)
    const [left, bottom, right, top] = values
    // Determine mode based on patterns
    let mode
    if (left === 0 && bottom === 0 && right === 0 && top === 0) {
      mode = 'none'
    } else if (left === right && bottom === top && left === bottom) {
      // All values are the same and non-zero
      mode = 'all'
      this.element.querySelector('[data-target="all"]').value = left
    } else if (left === right && bottom === top) {
      // Horizontal/vertical pattern
      mode = 'horizontal_vertical'
      this.element.querySelector('[data-target="horizontal"]').value = left
      this.element.querySelector('[data-target="vertical"]').value = bottom
    } else {
      // Custom values
      mode = 'custom'
      this.element.querySelector('[data-target="left"]').value = left
      this.element.querySelector('[data-target="bottom"]').value = bottom
      this.element.querySelector('[data-target="right"]').value = right
      this.element.querySelector('[data-target="top"]').value = top
    }

    // Set the radio button
    const radio = this.element.querySelector(`input[value="${mode}"]`)
    if (radio) {
      radio.checked = true
    }

    // Show the appropriate inputs
    this.updateBorderInputs(mode)

    // Always update hidden input with normalized value
    this.updateHiddenInput(values)
  }

  updateMode(event) {
    this.updateBorderInputs(event.target.value)
    
    // Reset values when mode changes
    const mode = event.target.value
    let values = [0, 0, 0, 0]

    if (mode === 'all') {
      const all = this.element.querySelector('[data-target="all"]').value || 0
      values = [all, all, all, all]
    } else if (mode === 'horizontal_vertical') {
      const h = this.element.querySelector('[data-target="horizontal"]').value || 0
      const v = this.element.querySelector('[data-target="vertical"]').value || 0
      values = [h, v, h, v]
    } else if (mode === 'custom') {
      values = [
        this.element.querySelector('[data-target="left"]').value || 0,
        this.element.querySelector('[data-target="bottom"]').value || 0,
        this.element.querySelector('[data-target="right"]').value || 0,
        this.element.querySelector('[data-target="top"]').value || 0
      ]
    }

    this.updateHiddenInput(values)
  }

  updateBorderInputs(mode) {
    this.inputsTarget.style.display = mode === 'none' ? 'none' : 'block'
    this.allTarget.style.display = mode === 'all' ? 'block' : 'none'
    this.hvTarget.style.display = mode === 'horizontal_vertical' ? 'block' : 'none'
    this.customTarget.style.display = mode === 'custom' ? 'block' : 'none'
  }

  updateHiddenInput(values) {
    let hiddenInput = this.element.querySelector('input[name="pdf[borders]"]')
    if (!hiddenInput) {
      hiddenInput = document.createElement('input')
      hiddenInput.type = 'hidden'
      hiddenInput.name = 'pdf[borders]'
      this.formTarget.appendChild(hiddenInput)
    }
    hiddenInput.value = values.join(' ')
  }

  submitForm(event) {
    const mode = this.element.querySelector('.border-mode-radio:checked').value
    let values = [0, 0, 0, 0]
    
    if (mode === 'all') {
      const value = this.element.querySelector('[data-target="all"]').value || 0
      values = [value, value, value, value]
    } else if (mode === 'horizontal_vertical') {
      const h = this.element.querySelector('[data-target="horizontal"]').value || 0
      const v = this.element.querySelector('[data-target="vertical"]').value || 0
      values = [h, v, h, v]
    } else if (mode === 'custom') {
      values = [
        this.element.querySelector('[data-target="left"]').value || 0,
        this.element.querySelector('[data-target="bottom"]').value || 0,
        this.element.querySelector('[data-target="right"]').value || 0,
        this.element.querySelector('[data-target="top"]').value || 0
      ]
    }

    this.updateHiddenInput(values)
  }
}