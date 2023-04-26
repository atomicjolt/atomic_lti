import { doLtiRedirect } from "./redirect"

const settings = {
  'state': 'state',
  'require_csrf': true,
  'lti_storage_params': {
    'target': '_parent',
    'origin_support_broken': true,
    'oidc_url': 'https://canvas.instructure.com/api/lti/authorize_redirect',
  },
};

describe('test', () => {

  beforeEach(() => {
    document.body.innerHTML = `
      <form action="https://assessments.atomicjolt.xyz/lti_launches/" method="POST">
          <input type="hidden" name="state" id="state" value="state" />
          <input type="hidden" name="id_token" id="id_token" value="id_token" />
          <input type="hidden" name="csrf_token" id="csrf_token" value="" />
      </form>
      <div id="error" class="hidden">error</div>
    `;
  });

  afterEach(() => {
    jest.restoreAllMocks();
    document.cookie = 'open_id_state=;Max-Age=-1';
  });

  test('submits form when cookie is present', () => {
    jest.spyOn(window.document, 'cookie', 'get').mockReturnValue('open_id_state=jwt');
    const mockSubmit = jest.fn()
    document.forms[0].submit = mockSubmit;
    doLtiRedirect(settings);
    expect(mockSubmit).toHaveBeenCalled();
  });

  test('submits form when cookie is not present and lti storage isn\'t available', () => {
    const mockSubmit = jest.fn()
    document.forms[0].submit = mockSubmit;
    doLtiRedirect({ ...settings, lti_storage_params: null });
    expect(mockSubmit).toHaveBeenCalled();
  });

  test('uses the lti storage api when available', async () => {
    const postMessageSpy = jest.spyOn(window, 'postMessage')
    doLtiRedirect(settings);
    await new Promise(process.nextTick);
    expect(postMessageSpy).toHaveBeenCalled();
    // TODO: Figure out how to test the postMessage API
  });
});
