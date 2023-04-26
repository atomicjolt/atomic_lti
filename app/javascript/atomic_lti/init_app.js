import { doLtiStorageLaunch, tryRequestStorageAccess } from "./lib/init"

window.onload = async () => {
  doLtiStorageLaunch(window.SETTINGS);
  window.LAUNCHED = true;
  document.getElementById("request_storage_access_link").
    onclick = () => tryRequestStorageAccess(window.SETTINGS);
}

