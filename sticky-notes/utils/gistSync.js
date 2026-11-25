.pragma library

var GIST_DESCRIPTION = "noctalia-sticky-notes";
var EMPTY_FILE_NAME = ".empty";
var API_BASE_URL = "https://api.github.com";

function syncNotes(operation, notes, callback) {
    if (!operation.current()) return;
    var token = operation.token;
    if (!token) {
        callback(false, operation.tr("sync.errors.missing-token"));
        return;
    }

    var gistId = operation.gistId;
    var normalizedNotes = Array.isArray(notes) ? notes : [];

    if (gistId) {
        getGistById(operation, token, gistId, function(success, gist, errorMessage) {
            if (success) {
                upsertGist(operation, token, gist, normalizedNotes, callback);
                return;
            }

            createOrFindGist(operation, token, normalizedNotes, callback);
        });
        return;
    }

    createOrFindGist(operation, token, normalizedNotes, callback);
}

function createOrFindGist(operation, token, notes, callback) {
    findManagedGist(operation, token, function(found, gist, errorMessage) {
        if (!found && errorMessage) {
            callback(false, errorMessage);
            return;
        }

        if (gist) {
            upsertGist(operation, token, gist, notes, callback);
            return;
        }

        var payload = {
            description: GIST_DESCRIPTION,
            "public": false,
            files: buildFilesPayload(notes, {})
        };

        requestJson(operation, "POST", API_BASE_URL + "/gists", token, payload, function(success, response, errorMessage) {
            if (!success) {
                callback(false, errorMessage);
                return;
            }

            if (operation.publishGistId(response.id))
                callback(true, operation.tr("sync.success.created"));
        });
    });
}

function upsertGist(operation, token, gist, notes, callback) {
    var payload = {
        description: GIST_DESCRIPTION,
        files: buildFilesPayload(notes, gist.files || {})
    };

    requestJson(operation, "PATCH", API_BASE_URL + "/gists/" + gist.id, token, payload, function(success, response, errorMessage) {
        if (!success) {
            callback(false, errorMessage);
            return;
        }

        if (operation.publishGistId(response.id || gist.id))
            callback(true, operation.tr("sync.success.updated"));
    });
}

function findManagedGist(operation, token, callback) {
    requestJson(operation, "GET", API_BASE_URL + "/gists?per_page=100", token, null, function(success, response, errorMessage) {
        if (!success) {
            callback(false, null, errorMessage);
            return;
        }

        var gists = Array.isArray(response) ? response : [];
        for (var i = 0; i < gists.length; i++) {
            if ((gists[i].description || "") === GIST_DESCRIPTION) {
                callback(true, gists[i], "");
                return;
            }
        }

        callback(false, null, "");
    });
}

function getGistById(operation, token, gistId, callback) {
    requestJson(operation, "GET", API_BASE_URL + "/gists/" + gistId, token, null, function(success, response, errorMessage, status) {
        if (!success) {
            callback(false, null, errorMessage);
            return;
        }

        callback(true, response, "");
    });
}

function buildFilesPayload(notes, existingFiles) {
    var files = {};
    var currentFileNames = {};

    for (var i = 0; i < notes.length; i++) {
        var note = notes[i];
        if (!note || !note.noteId)
            continue;

        currentFileNames[note.noteId] = true;
        files[note.noteId] = {
            content: note.content || ""
        };
    }

    if (notes.length === 0) {
        files[EMPTY_FILE_NAME] = {
            content: ""
        };
    } else if (existingFiles && existingFiles[EMPTY_FILE_NAME]) {
        files[EMPTY_FILE_NAME] = null;
    }

    for (var fileName in existingFiles) {
        if (!existingFiles.hasOwnProperty(fileName))
            continue;

        if (fileName === EMPTY_FILE_NAME) {
            continue;
        }

        if (!currentFileNames[fileName]) {
            files[fileName] = null;
        }
    }

    return files;
}

function requestJson(operation, method, url, token, body, callback) {
    if (!operation.current()) return;
    var xhr = new XMLHttpRequest();
    operation.requests.push(xhr);
    xhr.open(method, url);
    xhr.setRequestHeader("Accept", "application/vnd.github+json");
    xhr.setRequestHeader("Authorization", "Bearer " + token);
    xhr.setRequestHeader("X-GitHub-Api-Version", "2022-11-28");

    if (body !== null && body !== undefined) {
        xhr.setRequestHeader("Content-Type", "application/json");
    }

    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE)
            return;
        operation.requests = operation.requests.filter(function(request) { return request !== xhr; });
        if (!operation.current()) return;

        var parsed = null;
        if (xhr.responseText && xhr.responseText.length > 0) {
            try {
                parsed = JSON.parse(xhr.responseText);
            } catch (e) {
                parsed = null;
            }
        }

        if (xhr.status >= 200 && xhr.status < 300) {
            callback(true, parsed, "", xhr.status);
            return;
        }

        var errorMessage = formatError(parsed, xhr.status);
        callback(false, parsed, errorMessage, xhr.status);
    };

    xhr.send(body !== null && body !== undefined ? JSON.stringify(body) : undefined);
}

function formatError(response, status) {
    if (response && response.message) {
        return response.message;
    }

    if (status === 0) {
        return "Network error";
    }

    return "GitHub API request failed (" + status + ")";
}
