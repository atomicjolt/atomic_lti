import { initOIDCLaunch } from '@atomicjolt/lti-client';
import type { InitSettings } from '@atomicjolt/lti-client/types';

declare global {
  interface Window {
    INIT_SETTINGS: InitSettings;
  }
}

const initSettings: InitSettings = window.INIT_SETTINGS;
initOIDCLaunch(initSettings);
