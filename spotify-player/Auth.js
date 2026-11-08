function formEncode(values) {
    return Object.keys(values).map(function(key) {
        return encodeURIComponent(key) + "=" + encodeURIComponent(values[key]);
    }).join("&");
}

// The caller owns lifetime and the selected input fence. This helper owns only
// the request/response contract, not preferences or a page's mutable state.
function requestToken(encodedCredentials, values, callback) {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "https://accounts.spotify.com/api/token");
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhr.setRequestHeader("Authorization", "Basic " + encodedCredentials);
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) return;
        var data;
        try { data = JSON.parse(xhr.responseText); }
        catch (error) { callback(null, "token-response"); return; }
        if (xhr.status < 200 || xhr.status >= 300 || typeof data.access_token !== "string" || !data.access_token || typeof data.expires_in !== "number" || !isFinite(data.expires_in)) {
            callback(null, "token-response"); return;
        }
        callback({accessToken: data.access_token, refreshToken: data.refresh_token, tokenExpiresAt: Date.now() + data.expires_in * 1000}, null);
    };
    xhr.send(formEncode(values));
    return xhr;
}
