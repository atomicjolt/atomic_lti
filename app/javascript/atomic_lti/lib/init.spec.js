import i18next from "i18next";
import { doLtiStorageLaunch, tryRequestStorageAccess, launchNewWindow } from "./init"

i18next
  .init({
    fallbackLng: 'en',
    keySeparator: false,
  });

const settings = {
  'state': 'state',
  'csrf_token': 'csrf',
  'response_url': 'https://canvas.instructure.com/api/lti/authorize_redirect?client_id=43460000000000539',
  'relaunch_init_url': 'https://test.atomicjolt.xyz/oidc/init?iss=https%3A%2F%2Fcanvas.instructure.com',
  'lti_storage_params': {
    'target': '_parent',
    'origin_support_broken': true,
    'oidc_url': 'https://canvas.instructure.com/api/lti/authorize_redirect',
  },
};

describe('test', () => {

  beforeEach(() => {
    document.body.innerHTML = `
      <div class="aj-main">
        <div id="error" class="hidden error">Error</div>
        <div id="main-content"></div>
      </div>
    `;
  });

  afterEach(() => {
    jest.restoreAllMocks();
    delete document.hasStorageAccess;
    delete document.requestStorageAccess;
    document.cookie = 'open_id_state=;Max-Age=-1';
  });

  test('launches in new window', () => {
    const openSpy = jest.spyOn(window, 'open');
    launchNewWindow(settings);
    expect(openSpy).toHaveBeenCalledWith(settings.relaunch_init_url);
    expect(document.getElementById('button_launch_new_window').disabled).toBe(true);
    expect(document.body.innerHTML).toContain("Please click");
    expect(document.body.innerHTML).not.toContain("enable cookies");
  });

  test('submits form when we have cookies', () => {
    jest.spyOn(window.document, 'cookie', 'get').mockReturnValue('open_id_state=jwt');
    const mockReplace = jest.fn()
    jest.spyOn(window, 'location', 'get').mockReturnValue({ replace: mockReplace });
    doLtiStorageLaunch(settings);
    expect(mockReplace).toHaveBeenCalledWith(settings.response_url);
  });

  test('shows cookie error when in top frame', () => {
    doLtiStorageLaunch({ ...settings, lti_storage_params: null });
    expect(document.body.innerHTML).toContain("check your browser");
    expect(document.body.innerHTML).not.toContain("Open in a new window");
  });

  test('shows launch in new window when not in top frame', () => {
    jest.spyOn(window, 'top', 'get').mockReturnValue({});
    doLtiStorageLaunch({ ...settings, lti_storage_params: null });
    expect(document.body.innerHTML).toContain("Open in a new window");
  });

  test('shows storage api access link when available and not in top frame', async () => {
    document.hasStorageAccess = () => Promise.resolve(false);
    document.requestStorageAccess = () => Promise.resolve(false);
    jest.spyOn(window, 'top', 'get').mockReturnValue({});
    doLtiStorageLaunch({ ...settings, lti_storage_params: null });
    await new Promise(process.nextTick);
    expect(document.body.innerHTML).toContain("enable cookies");
  });

  test('doesn\'t show storage api access link when not available', async () => {
    document.hasStorageAccess = () => Promise.reject();
    document.requestStorageAccess = () => Promise.resolve(true);
    jest.spyOn(window, 'top', 'get').mockReturnValue({});
    doLtiStorageLaunch({ ...settings, lti_storage_params: null });
    await new Promise(process.nextTick);
    expect(document.body.innerHTML).not.toContain("enable cookies");
  });

  test('doesn\'t show storage api access link when we already have access', async () => {
    document.hasStorageAccess = () => Promise.resolve(true);
    document.requestStorageAccess = () => Promise.resolve(true);
    jest.spyOn(window, 'top', 'get').mockReturnValue({});
    doLtiStorageLaunch({ ...settings, lti_storage_params: null });
    await new Promise(process.nextTick);
    expect(document.body.innerHTML).not.toContain("enable cookies");
  });

  test('redirects and sets cookie if storage access is granted', async () => {
    document.requestStorageAccess = () => Promise.resolve(true);
    const mockReplace = jest.fn()
    jest.spyOn(window, 'location', 'get').mockReturnValue({ replace: mockReplace });
    const cookieSet = jest.spyOn(document, 'cookie', 'set');
    tryRequestStorageAccess(settings);
    await new Promise(process.nextTick);
    expect(mockReplace).toHaveBeenCalledWith(settings.response_url);
    expect(cookieSet).toHaveBeenCalledWith('open_id_state=csrf; path=/; max-age=300; SameSite=None ;');
  });

  test('shows an error if storage access is not granted', async () => {
    const logSpy = jest.spyOn(console, 'log').mockReturnValue(null);
    document.requestStorageAccess = () => new Promise(function() { throw new Error('No Access'); });
    tryRequestStorageAccess(settings);
    await new Promise(process.nextTick);
    expect(document.body.innerHTML).toContain("browser prevented");
    expect(logSpy).toHaveBeenCalled();
  });

  test('uses the lti storage api when available', async () => {
    const postMessageSpy = jest.spyOn(window, 'postMessage')
    doLtiStorageLaunch(settings);
    await new Promise(process.nextTick);
    expect(postMessageSpy).toHaveBeenCalled();
    // TODO: Figure out how to test the postMessage API
  });
});
