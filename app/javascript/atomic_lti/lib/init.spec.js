import { doLtiStorageLaunch, tryRequestStorageAccess } from "./init"

const settings = {
  'state': 'state',
  'csrf_token': 'csrf',
  'response_url': 'https://canvas.instructure.com/api/lti/authorize_redirect?client_id=43460000000000539',
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
        <div id="launch_new_window" class="hidden">Launch new window</div>
        <div id="cookie_error" class="hidden">Cookie error</div>
        <div id="request_storage_access" class="hidden">Request storage access</div>
        <div id="request_storage_access_error" class="hidden">Request storage access error</div>
      </div>
    `;
  });

  afterEach(() => {
    jest.restoreAllMocks();
    delete document.hasStorageAccess;
    delete document.requestStorageAccess;
    document.cookie = 'open_id_state=;Max-Age=-1';
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
    expect(document.getElementById('cookie_error').classList.contains('hidden')).toBe(false)
  });

  test('shows launch in new window when not in top frame', () => {
    jest.spyOn(window, 'top', 'get').mockReturnValue({});
    doLtiStorageLaunch({ ...settings, lti_storage_params: null });
    expect(document.getElementById('cookie_error').classList.contains('hidden')).toBe(true)
    expect(document.getElementById('launch_new_window').classList.contains('hidden')).toBe(false)
  });

  test('shows storage api access link when available and not in top frame', async () => {
    document.hasStorageAccess = () => Promise.resolve(false);
    document.requestStorageAccess = () => Promise.resolve(false);
    jest.spyOn(window, 'top', 'get').mockReturnValue({});
    doLtiStorageLaunch({ ...settings, lti_storage_params: null });
    await new Promise(process.nextTick);
    expect(document.getElementById('request_storage_access').classList.contains('hidden')).toBe(false)
    expect(document.getElementById('launch_new_window').classList.contains('hidden')).toBe(false)
  });

  test('doesn\'t show storage api access link when not available', async () => {
    document.hasStorageAccess = () => Promise.resolve(false);
    document.requestStorageAccess = () => Promise.resolve(false);
    jest.spyOn(window, 'top', 'get').mockReturnValue({});
    doLtiStorageLaunch({ ...settings, lti_storage_params: null });
    await new Promise(process.nextTick);
    expect(document.getElementById('request_storage_access').classList.contains('hidden')).toBe(false)
    expect(document.getElementById('launch_new_window').classList.contains('hidden')).toBe(false)
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
    expect(document.getElementById('request_storage_access_error').classList.contains('hidden')).toBe(false)
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
