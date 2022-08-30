import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="music-index"
export default class extends Controller {
  connect() {
    console.log("music")
  }

  favorite(event) {
    console.log("fav")
    var icon_color = event.target.style.color
    console.log(icon_color)
    if (icon_color === "rgb(14, 205, 171)") {
      event.target.style.color = ""
    } else {
      event.target.style.color = "rgb(14, 205, 171)"
    }
  }
}