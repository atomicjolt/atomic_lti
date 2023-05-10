import i18next from "i18next";
import LanguageDetector from 'i18next-browser-languagedetector';
import { doLtiStorageLaunch, tryRequestStorageAccess, launchNewWindow } from "./lib/init"
import es from "./locale/es.json"
import fr from "./locale/fr.json"

i18next
  .use(LanguageDetector)
  .init({
    detection: { order: ['querystring', 'navigator'] },
    fallbackLng: 'en',
    keySeparator: false,
  });

i18next.addResourceBundle('es', 'translation', es);
i18next.addResourceBundle('fr', 'translation', fr);
i18next.changeLanguage()

window.onload = async () => {
  doLtiStorageLaunch(window.SETTINGS);
  window.LAUNCHED = true;
}
