import { doLtiStorageLaunch, tryRequestStorageAccess, launchNewWindow } from "./lib/init"

window.onload = async () => {
  doLtiStorageLaunch(window.SETTINGS);
  window.LAUNCHED = true;
  document.getElementById("request_storage_access_link").
    onclick = () => tryRequestStorageAccess(window.SETTINGS);
  document.getElementById("button_launch_new_window").
    onclick = () => launchNewWindow(window.SETTINGS);
}
