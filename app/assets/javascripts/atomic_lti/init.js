function showError() {
  document.getElementById('error').classList.remove('hidden');
}

function showLaunchNewWindow() {
  document.getElementById('launch_new_window').classList.remove('hidden');
}

function showCookieError() {
  document.getElementById('cookie_error').classList.remove('hidden');
}

function showRequestStorageAccess() {
  document.getElementById('request_storage_access').classList.remove('hidden');
}

function showRequestStorageError() {
  document.getElementById('request_storage_access_error').classList.remove('hidden');
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

function tryRequestStorageAccess(settings) {
  document.requestStorageAccess()
    .then(() => {
      // We should have cookies now
      setCookie(settings);
      window.location.replace(settings.response_url);
    })
    .catch((e) => {
      console.log(e);
      showRequestStorageError();
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

async function doLtiStorageLaunch(settings) {
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
    showLaunchNewWindow();
    if (hasStorageAccessAPI()) {
      // We have storage access API, which will work for Safari as long as the
      // user already has used the application in the top layer and it set a cookie.
      try {
        let hasAccess = await document.hasStorageAccess();
        if (!hasAccess) {
          showRequestStorageAccess();
          return;
        }
      } catch(e) {
        console.log(e);
      }
    }
  } else {
    showCookieError();
  }
}

if (typeof module !== 'undefined') {
  module.exports.doLtiStorageLaunch = doLtiStorageLaunch;
  module.exports.tryRequestStorageAccess = tryRequestStorageAccess;
}
