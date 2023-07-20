import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="summaries-index"
export default class extends Controller {
  connect() {
    console.log("summary")
  }
}
