// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import {
  Collapse,
  initTWE,
} from "tw-elements";

initTWE({ Collapse });
