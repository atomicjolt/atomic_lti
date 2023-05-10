import i18next from "i18next";

function showError() {
  const container = document.getElementById('main-content');
  container.innerHTML = `
    <div class="u-flex aj-centered-message">
      <i class="material-icons-outlined aj-icon" aria-hidden="true">warning</i>
      <p class="aj-text translate">
        ${ i18next.t("There was an error launching the LTI tool. Please reload and try again.") }
      </p>
    </div>
  `;
}

function privacyHtml(settings) {
  return i18next.t(settings.privacy_policy_message || `We use cookies for login and security`) + ' '
    + i18next.t(`Learn more in our <a href='{{url}}' target='_blank'>privacy policy</a>.`);
}


function showLaunchNewWindow(settings, options) {
  const { disableLaunch, showRequestStorageAccess, showStorageAccessDenied } = options;
  const container = document.getElementById('main-content');
  container.innerHTML = `
    <div class="aj-centered-message">
      <h1 class="aj-title">
        <i class="material-icons-outlined aj-icon" aria-hidden="true">cookie_off</i>
        ${ i18next.t("Cookies Required") }
      </h1>
      <p class="aj-text">
        ${ privacyHtml(settings) } </p>
      <p class="aj-text">
        ${ i18next.t('Please click the button below to reload in a new window.') }
      </p>
      <button id="button_launch_new_window" class="aj-btn aj-btn--blue" ${ disableLaunch? 'disabled=""' : '' } >
        ${ i18next.t('Open in a new window') }
      </button>
      </a>
      ${ showRequestStorageAccess? `
        <div id="request_storage_access">
          <p class="aj-text">
            ${ i18next.t("If you have used this application before, your browser may allow you to <a id='request_storage_access_link' href='#'>enable cookies</a> and prevent this message in the future.") }
          </p>
        </div>
       `:''}
      ${ showStorageAccessDenied? `
      <div id="request_storage_access_error" class="u-flex">
        <i class="material-icons-outlined aj-icon" aria-hidden="true">warning</i>
        <p class="aj-text">
        ${ i18next.t('The browser prevented access.  Try launching in a new window first and then clicking this option again next time. If that doesn\'t work check your privacy settings. Some browsers will prevent all third party cookies.') }
        </p>
      </div>
      `:''}
    </div>
  `;
  document.getElementById("button_launch_new_window").onclick = () => launchNewWindow(window.SETTINGS);
  if (showRequestStorageAccess) {
    document.getElementById("request_storage_access_link").
      onclick = () => tryRequestStorageAccess(window.SETTINGS);
  }
}

function showCookieError(settings) {
  const container = document.getElementById('main-content');
  container.innerHTML = `
    <div id="cookie_error" class="aj-centered-message">
      <h1 class="aj-title">
        <i class="material-icons-outlined aj-icon" aria-hidden="true">cookie_off</i>
        ${ i18next.t("Cookies Required") }
      </h1>
      <p class="aj-text">
        ${ privacyHtml(settings) }
      </p>
      <p class="aj-text">
        ${ i18next.t("Please check your browser settings and enable cookies.") }
      </p>
    </div>
  `;
}

export function launchNewWindow(settings) {
  window.open(settings.relaunch_init_url);
  showLaunchNewWindow(settings, { disableLaunch: true });
}

function storeCsrf(state, csrf_token, storage_params) {
  return new Promise((resolve, reject) => {
    let platformOrigin = new URL(storage_params.oidc_url).origin;
    let frameName = storage_params.target;
    let parent = window.parent || window.opener;
    let targetFrame = frameName === "_parent" ? parent : parent.frames[frameName];

    if (storage_params.origin_support_broken) {
      // The spec requires that the message's target origin be set to the platform's OIDC Authorization url
      // but Canvas does not yet support this, so we have to use '*'.
      platformOrigin = '*'
    }

    let timeout = setTimeout(() => {
      console.log("postMessage timeout");
      reject(new Error('Timeout while waiting for platform response'));
    }, 2000);

    let receiveMessage = (event) => {
        if (typeof event.data === "object" &&
            event.data.subject === "lti.put_data.response" &&
            event.data.message_id === state &&
            (event.origin === platformOrigin || platformOrigin === "*")) {

          removeEventListener('message', receiveMessage);
          clearTimeout(timeout);

          if (event.data.error) {
              // handle errors
              console.log(event.data.error.code)
              console.log(event.data.error.message)
              reject(new Error(event.data.errormessage));
          }
          resolve();
        }
    };

    window.addEventListener('message', receiveMessage);
    targetFrame.postMessage({
            "subject": "lti.put_data",
            "message_id": state,
            "key": "atomic_lti_" + state,
            "value": csrf_token
          } , platformOrigin );

    // Platform should post a message back

  });
}

export function tryRequestStorageAccess(settings) {
  document.requestStorageAccess()
    .then(() => {
      // We should have cookies now
      setCookie(settings);
      window.location.replace(settings.response_url);
    })
    .catch((e) => {
      console.log(e);
      showLaunchNewWindow(settings, { showStorageAccessDenied: true });
    });
}

async function checkForStorageAccess() {
  try {
    return await document.hasStorageAccess();
  } catch(e) {
    return false;
  }
}

function hasCookie(settings) {
  return document.cookie.match('(^|;)\\s*open_id_' + settings.state);
}

function setCookie(settings) {
  document.cookie = 'open_id_' + settings.state +'=' + settings.csrf_token + '; path=/; max-age=300; SameSite=None ;'
}

function hasStorageAccessAPI() {
  return typeof document.hasStorageAccess === 'function'
    && typeof document.requestStorageAccess === 'function';
}

export async function doLtiStorageLaunch(settings) {
  let submitToPlatform = () => { window.location.replace(settings.response_url) };

  if (hasCookie(settings)) {
    // We have cookies
    return submitToPlatform();
  }

  if (settings.lti_storage_params) {
    // We have lti postMessage storage
    try {
      await storeCsrf(settings.state, settings.csrf_token, settings.lti_storage_params);
      return submitToPlatform();
    } catch (e) {
      console.log(e);
    }
  }

  if (window.self !== window.top) {
    let showRequestStorageAccess = false;
    if (hasStorageAccessAPI()) {
      // We have storage access API, which will work for Safari as long as the
      // user already has used the application in the top layer and it set a cookie.
      try {
        let hasAccess = await document.hasStorageAccess();
        if (!hasAccess) {
          showRequestStorageAccess = true;
        }
      } catch(e) {
        console.log(e);
      }
    }
    showLaunchNewWindow(settings, { showRequestStorageAccess });
  } else {
    showCookieError(settings);
  }
}
