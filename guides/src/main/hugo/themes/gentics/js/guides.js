(function () {
  const VERSIONS_JSON = 'https://www.gentics.com/guides/majorversions.json';

  function getCurrentVersion() {
    return (typeof window.major_version !== 'undefined') ? String(window.major_version) : null;
  }

  // Derives the target version's URL from the current page URL.
  // Uses split/join instead of replace() to handle multiple occurrences of the version string.
  // Falls back to replacing /latest/ if the version segment isn't found in the URL.
  function buildVersionUrl(targetVersion) {
    const currentUrl = window.location.href;
    const currentVersion = getCurrentVersion();

    if (currentVersion && currentUrl.includes(currentVersion)) {
      return currentUrl.split(currentVersion).join(targetVersion);
    }

    if (currentUrl.includes('/latest/')) {
      return currentUrl.replace('/latest/', '/' + targetVersion + '/');
    }

    return null;
  }

  async function isReachable(url) {
    try {
      const response = await fetch(url, { method: 'HEAD' });
      return response.ok;
    } catch {
      return false;
    }
  }

  async function buildVersionEntries(versions) {
    const currentVersion = getCurrentVersion();
    const container = document.querySelector('.version-entries');
    if (!container) return;

    // Build list: check reachability for non-active versions in parallel
    const checks = versions.map(async (v) => {
      const version = String(v.version);
      const label = 'CMP ' + version;

      if (version === currentVersion) {
        return { label, active: true, url: null };
      }

      const url = buildVersionUrl(version);
      if (!url) return null;

      const reachable = await isReachable(url);
      if (!reachable) return null;

      return { label, active: false, url };
    });

    // Wait for all HEAD requests to settle, drop unreachable entries (null)
    const results = (await Promise.all(checks)).filter(Boolean);

    container.innerHTML = '';
    results.forEach((entry, i) => {
      if (entry.active) {
        const span = document.createElement('span');
        span.className = 'version-entry active';
        span.textContent = entry.label;
        container.appendChild(span);
      } else {
        const a = document.createElement('a');
        a.className = 'version-entry';
        a.href = entry.url;
        a.textContent = entry.label;
        container.appendChild(a);
      }

      if (i < results.length - 1) {
        container.appendChild(document.createElement('hr'));
      }
    });
  }

  async function init() {
    const currentVersion = getCurrentVersion();
    const versionName = document.querySelector('.versions-switch .version-name');
    if (versionName && currentVersion) {
      versionName.textContent = 'CMP ' + currentVersion;
    }

    try {
      const response = await fetch(VERSIONS_JSON);
      if (!response.ok) return;
      const data = await response.json();
      await buildVersionEntries(data.majorversions || []);
    } catch (e) {
      console.warn('guides.js: failed to load versions', e);
    }
  }

  // Safe to call whether the script is in <head> or end of <body>
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
