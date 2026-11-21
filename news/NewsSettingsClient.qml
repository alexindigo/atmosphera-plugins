import QtQuick

// One producer per captured API, shared by all of its renderers.
Item {
  id: client
  required property var settingsContext
  required property var pluginApi
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: settingsContext.settingsView
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property string apiKey: cfg.apiKey || defaults.apiKey || "YOUR_API_KEY_HERE"
  readonly property string country: cfg.country || defaults.country || "us"
  readonly property string language: cfg.language || defaults.language || "en"
  readonly property string category: cfg.category || defaults.category || "general"
  readonly property int refreshInterval: cfg.refreshInterval || defaults.refreshInterval || 30
  readonly property int maxHeadlines: cfg.maxHeadlines || defaults.maxHeadlines || 10
  readonly property var countryLanguageMap: ({
    "us": "en", "gb": "en", "ca": "en", "au": "en", "de": "de", "fr": "fr",
    "it": "it", "es": "es", "jp": "ja", "kr": "ko", "in": "en", "br": "pt",
    "nl": "nl", "se": "sv", "no": "no", "mx": "es"
  })
  readonly property string baseUrl: "https://newsapi.org/v2"
  readonly property string sourceKey: JSON.stringify([apiKey, country, language, category, maxHeadlines])
  readonly property bool configured: apiKey !== "YOUR_API_KEY_HERE" && apiKey !== ""
  property var newsData: []
  property string errorMessage: ""
  property bool isLoading: false
  property var _request: null
  property int _generation: 0
  property bool _constructed: false

  function cancel() {
    ++_generation;
    var previous = _request;
    _request = null;
    if (previous) { previous.onreadystatechange = function() {}; previous.abort(); }
    isLoading = false;
  }
  function replaceSource() {
    cancel();
    newsData = [];
    errorMessage = "";
    if (current) requestRefresh();
  }
  function requestRefresh() { fetchNews(); }
  function fetchNews() {
    if (!current || isLoading) return;
    if (!configured) { errorMessage = "API key not configured"; return; }
    var generation = _generation, limit = maxHeadlines;
    var lang = countryLanguageMap[country] || language || "en";
    var query = category !== "general" ? category : "news OR headlines";
    var url = baseUrl + "/everything?q=" + encodeURIComponent(query) + "&language=" + lang + "&sortBy=publishedAt&pageSize=" + limit + "&apiKey=" + apiKey;
    var xhr = new XMLHttpRequest();
    _request = xhr;
    isLoading = true;
    errorMessage = "";
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== XMLHttpRequest.DONE || !client.current || generation !== client._generation || client._request !== xhr) return;
      client._request = null;
      client.isLoading = false;
      if (xhr.status === 200) {
        try {
          var response = JSON.parse(xhr.responseText);
          if (response.status === "ok" && response.articles) client.newsData = response.articles.slice(0, limit);
          else client.errorMessage = response.message || "API error";
        } catch (error) { client.errorMessage = "Failed to parse response"; }
      } else client.errorMessage = xhr.status === 401 ? "Invalid API key" : xhr.status === 429 ? "Rate limit exceeded" : xhr.status === 0 ? "Network error" : "HTTP error " + xhr.status;
    };
    xhr.open("GET", url);
    xhr.send();
  }
  Timer {
    interval: client.refreshInterval * 60 * 1000
    running: client.current && client.configured
    repeat: true
    onTriggered: client.fetchNews()
  }
  onSourceKeyChanged: if (_constructed) replaceSource()
  onCurrentChanged: if (!current && _constructed) { cancel(); retire(client); }
  Component.onCompleted: { _constructed = true; replaceSource(); }
}
