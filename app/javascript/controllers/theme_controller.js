import { Controller } from "@hotwired/stimulus";

// Toggles between light (default) and dark themes by adding/removing the
// `.dark` class on <html>. Preference is persisted to localStorage so it
// survives page reloads. Default is light.
const STORAGE_KEY = "pecha-theme";

export default class extends Controller {
  connect() {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved === "dark") {
      document.documentElement.classList.add("dark");
    }
  }

  toggle(event) {
    event?.preventDefault();
    const root = document.documentElement;
    const willBeDark = !root.classList.contains("dark");
    root.classList.toggle("dark", willBeDark);
    localStorage.setItem(STORAGE_KEY, willBeDark ? "dark" : "light");
  }
}
