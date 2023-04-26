import { doLtiRedirect } from "./lib/redirect"

window.onload = async () => doLtiRedirect(window.SETTINGS);
