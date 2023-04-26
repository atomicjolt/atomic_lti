function submitForm() {
  document.forms[0].submit();
}

function showError() {
  document.getElementById('error').classList.remove('hidden');
}

function hasCookie(settings) {
  return document.cookie.match('(^|;)\\s*open_id_' + settings.state);
}

function loadCsrf(state, storage_params) {
  return new Promise((resolve, reject) => {
    let platformOrigin = new URL(storage_params.oidc_url).origin;
    let frameName = storage_params.target;
    let parent = window.parent || window.opener;
    let targetFrame = frameName === "_parent" ? parent : parent.frames[frameName];

    if (storage_params.origin_support_broken) {
      // The spec requires that the message's target origin be set to the platform's OIDC Authorization url
      // but Canvas does not yet support this, so we have to use '*'.
      platformOrigin = '*';
    }

    let timeout = setTimeout(() => {
      console.log("postMessage timeout");
      reject(new Error('Timeout while waiting for platform response'));
    }, 2000);

    let receiveMessage = (event) => {
      if (typeof event.data === "object" &&
          event.data.subject === "lti.get_data.response" &&
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
        resolve(event.data.value);
      }
    };
    window.addEventListener('message', receiveMessage);

    targetFrame.postMessage({
            "subject": "lti.get_data",
            "message_id": state,
            "key": "atomic_lti_" + state,
          } , platformOrigin );

    // Platform will post a message back
  });
}

export async function doLtiRedirect(settings) {
  if (hasCookie(settings) || !settings.require_csrf) {
    return submitForm();
  }

  if (settings.lti_storage_params) {
    // We have lti postMessage storage
    try {
      let csrf_token = await loadCsrf(settings.state, settings.lti_storage_params);
      document.getElementsByName("csrf_token")[0].value = csrf_token;
      return submitForm();
    } catch (e) {
      console.log(e);
      showError();
    }
  }
  submitForm();
}
