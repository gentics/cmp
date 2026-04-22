
// ============================================
// FILTER FUNCTIONALITY
// ============================================

const activeFilters = new Set();

// Make toggle globally available
window.toggle = function(component) {
  const navId = `${component}_nav`;
  const navItem = document.getElementById(navId);
  if (!navItem) return;

  // Toggle active class on the nav item
  if (activeFilters.has(component)) {
    activeFilters.delete(component);
    navItem.classList.remove('selected');
  } else {
    activeFilters.add(component);
    navItem.classList.add('selected');
  }

  applyFilters();
};

function applyFilters() {
  //sections + rightNavComponents
  const combined = document.querySelectorAll('#changelog section, #dependency-report section, #right-panel li.right-nav-component');
  const isAnyFilterActive = activeFilters.size > 0;


  combined.forEach(element => {
    // If no filters are active, show everything
    if (!isAnyFilterActive) {
      element.style.display = '';
      return;
    }

    // Check if section matches any active filter
    // Section classes expected: "component_cms", "component_aloha", etc.
    let shouldShow = false;
    for (const filter of activeFilters) {
      if (element.classList.contains(`component_${filter}`)) {
        shouldShow = true;
        break;
      }
    }

    element.style.display = shouldShow ? '' : 'none';
  });



  
  // Optional: Hide version titles if all their sections are hidden?
  // Current HTML structure:
  // <div class="title-wrapper">...</div>
  // <section>...</section>
  // <section>...</section>
  // ...
  // <div class="title-wrapper">...</div>
  
  // This logic is a bit more complex because the title wrappers aren't semantic parents of the sections.
  // We can skip this for now or try to handle it if requested. 
  // Given the structure, simple section toggling is the safest first step.
}


// Event Delegation for Copy Buttons
document.addEventListener('click', (event) => {
  const btn = event.target.closest('.copy-link-btn');
  if (!btn) return;

  const targetId = btn.dataset.linkTarget;
  if (!targetId) return;

  copyChangelogLink(btn, targetId);
});

function copyChangelogLink(btn, hash) {
  // Prevent execution if already in the "copied" state
  if (btn.dataset.isCopying) {
    return;
  }

  const url = window.location.origin + window.location.pathname + hash;
  
  navigator.clipboard.writeText(url).then(() => {
    // Lock the button
    btn.dataset.isCopying = "true";

    // Find the icon element
    const icon = btn.querySelector('.icon');
    
    // Switch to check icon
    if (icon) {
      icon.classList.remove('icon-link');
      icon.classList.add('icon-check');
    }
    
    // 2. Show Tooltip
    // Create tooltip element
    const tooltip = document.createElement('span');
    tooltip.className = 'copy-tooltip';
    tooltip.textContent = 'Copied!';
    
    document.body.appendChild(tooltip);
    
    const rect = btn.getBoundingClientRect();
    
    // Position right of the button (fixed positioning)
    // Vertically centered relative to button center
    tooltip.style.top = (rect.top + (rect.height / 2)) + 'px'; 
    tooltip.style.left = (rect.right + 8) + 'px'; // 8px gap
    
    // Add visible class next frame for fade-in transition
    requestAnimationFrame(() => {
      tooltip.classList.add('visible');
    });

    // 3. Revert after 2s
    setTimeout(() => {
      // Revert icon
      if (icon) {
        icon.classList.remove('icon-check');
        icon.classList.add('icon-link');
      }
      
      // Unlock the button
      delete btn.dataset.isCopying;
      
      // Remove tooltip
      tooltip.classList.remove('visible');
      setTimeout(() => {
        if(tooltip.parentNode) tooltip.parentNode.removeChild(tooltip);
      }, 200); // wait for 0.2s transition
      
    }, 2000);
  }).catch(err => {
    console.error('Failed to copy: ', err);
  });
}

function handleHashNavigation() {
  const hash = window.location.hash;
  if (hash) {
    // Escape special characters in ID selectors if needed, or simply getElementById
    // The hash includes '#', so strip it
    const id = hash.substring(1);
    const targetElement = document.getElementById(id);
    
    if (targetElement) {
      // 1. Smooth scroll
      targetElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
      // 2. Highlight effect
      // Remove class from any previous highlight
      document.querySelectorAll('.target-highlight').forEach(el => {
        el.classList.remove('target-highlight');
      });
      
      // Add class to current target -> triggers CSS animation
      // Slight delay to ensure scroll starts/happens visibly
      setTimeout(() => {
        targetElement.classList.add('target-highlight');
      }, 300);
    }
  }
}

function addMainNavigation(){
   const mainNav = document.querySelector('#main-nav');
   const changelogBasePath = (mainNav?.dataset?.changelogbasepath || "./").replace(/static\/$/, "") ;
   
   fetch(changelogBasePath + '/static/majorversions.json')
    .then(response => response.json())
    .then(data => {
      const navList = document.querySelector('#main-nav .nav-list');
      const currentVersionSubmenu = document.querySelector('#nav-currentversion-submenu');
      const currentMajorVersion = currentVersionSubmenu?.dataset?.majorversion || 0;
      const addVersionsTextElements = document.querySelectorAll('.addDynamicLatestVersion');

      //dependency report does not have major versions in navigation
      if(mainNav?.dataset?.dependencyreport !== 'true'){
        data.majorversions.forEach(versionObj => {
          const li = document.createElement('li');
          li.id = "nav-" + versionObj.version;
          const a = document.createElement('a');
          a.href = changelogBasePath + versionObj.version +".0";
          a.className = 'nav-link';
          a.textContent = mainNav?.dataset?.changelogtitle + " " + versionObj.version;
          li.appendChild(a);

          let className = "nav-item";
          if(currentMajorVersion == versionObj.version){
            className = "nav-item expandable is-expanded";
            if(currentVersionSubmenu?.dataset?.markactive == "true"){
              className = className + " active";
            }
            li.appendChild(currentVersionSubmenu.children[0]);
          }
          li.className = className;


          navList.appendChild(li);
        });
      }

      //add latest major version number to spans
      addVersionsTextElements.forEach(textElem => {
        textElem.textContent = data.majorversions[0]?.version || "";
      });
    })
    .catch(error => console.error('Failed to major version list:', error));
}

function createChangelogOverview(){
  const timelineContainer = document.querySelector('.timeline-container');
  if (!timelineContainer) {
    return;
  }

  const mainNav = document.querySelector('#main-nav');
  const changelogBasePath = mainNav?.dataset?.changelogbasepath || './'.replace(/static\/$/, "") ;

  fetch(changelogBasePath + '/static/majorversions.json')
    .then(response => response.json())
    .then(data => {
      timelineContainer.innerHTML = '';

      data.majorversions.forEach((versionObj, index) => {

        const entry = document.createElement('div');
        entry.className = 'timeline-entry';
        entry.innerHTML = `
          <div class="timeline-marker"></div>
          <div class="timeline-content">
            <div class="timeline-date">${versionObj.date}</div>
            <div class="timeline-card">
              <div class="timeline-image-placeholder gradient-variant-1">
                <span>${mainNav?.dataset?.changelogtitle} ${versionObj.version}</span>
              </div>
              <div class="timeline-body">
                <h3>${mainNav?.dataset?.changelogtitle} ${versionObj.version}</h3>
                <p>${versionObj.description}</p>
                <a href="${versionObj.version}.0/" class="btn-read-more">View ${versionObj.version}.x Changelogs →</a>
              </div>
            </div>
          </div>
        `;

        timelineContainer.appendChild(entry);
      });
    })
    .catch(error => console.error('Failed to load major version list:', error));
}


function createRightPanelNav() {
  // Prevent duplicate navigation if already created
  const rightPanel = document.getElementById('right-panel');
  if (rightPanel.querySelector('ul')) {
    return;
  }

  const ul = document.createElement('ul');

  // Determine context: Changelog or Dependency Report
  const changelog = document.getElementById('changelog');
  const dependencyReport = document.getElementById('dependency-report');

  let navItems = [];

  if (changelog) {
    // Changelog Logic
    // Strategy: 
    // 1. Check if there are any h2 (Versions)
    // 2. If yes: h2 = Level 1, section h4 = Level 2 (indent)
    // 3. If no: section h4 = Level 1

    const h2s = document.querySelectorAll('#changelog .title-wrapper > h2');
    const hasH2 = h2s.length > 0;

    if (hasH2) {
      // Complex structure (e.g. Changelog Hub or Full Changelog)
      // Iterate through container to keep order
      const containers = document.querySelectorAll('#changelog .title-wrapper, #changelog section');

      containers.forEach(container => {
        // Case 1: Title Wrapper with H2
        if (container.classList.contains('title-wrapper')) {
          const h2 = container.querySelector('h2');
          if (h2) {
            navItems.push({
              element: container,
              text: h2.textContent,
              id: container.id || h2.id, // Prefer container ID if available
              isIndent: false,
              versionElement: true
            });
          }
        }
        // Case 2: Section (Component)
        else if (container.tagName.toLowerCase() === 'section') {
          const h4 = container.querySelector('h4');
          if (h4) {
            navItems.push({
              element: container,
              text: h4.textContent,
              id: container.id,
              isIndent: true
            });
          }
        }
      });

    } else {
      // Simple structure (e.g. Single Version) -> Flattened
      const sections = document.querySelectorAll('#changelog section');
      sections.forEach(section => {
        const h4 = section.querySelector('h4');
        if (h4) {
          navItems.push({
            element: section,
            text: h4.textContent,
            id: section.id,
            isIndent: false
          });
        }
      });
    }

  } else if (dependencyReport) {
    // Dependency Report Logic
    // Structure: section.component (Level 1) -> article.sub-component (Level 2)
    // We iterate sections, adding them, then their children

    const components = document.querySelectorAll('#dependency-report .component');

    components.forEach(component => {
      // Add Component (Level 1)
      const h4 = component.querySelector('h4');
      if (h4) {
        navItems.push({
          element: component,
          text: h4.textContent,
          id: component.id,
          isIndent: false
        });
      }

      // Add Sub-Components (Level 2)
      const subComponents = component.querySelectorAll('.sub-component');
      subComponents.forEach(sub => {
        const h5 = sub.querySelector('h5');
        if (h5) {
          navItems.push({
            element: sub, // anchor to the sub-component itself
            text: h5.textContent,
            id: sub.id,
            parentComponent: sub.dataset?.parentcomponent || null,
            isIndent: true
          });
        }
      });
    });
  }

  if (navItems.length === 0) return;

  let rightPanelTitle = rightPanel.dataset?.title || "Content of this page";

  rightPanel.innerHTML = `<div class="right-panel-header">
        <span class="icon-content"></span>
        <h5 id="right-panel-title">` + rightPanelTitle + `</h5>
        <button class="right-panel-top"><span class="icon-home-up"></span></button>
      </div>`;

  // Render List
  navItems.forEach(item => {
    let id = item.id;
    const text = item.text;

    // Fallback ID generation
    if (!id && text) {
      id = text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
      if (item.element && !item.element.id) {
        item.element.id = id;
      }
    }

    if (!text || !id) return;

    const li = document.createElement('li');
    const a = document.createElement('a');
    a.href = `#${id}`;
    a.textContent = text;

    if (item.isIndent) {
      li.classList.add('indent');
    }

    //do not add classes to version elements - otherwise they are filtered out
    if(item.versionElement !== true){
      li.classList.add("right-nav-component");
      li.classList.add("component_" + item.id);
      if(item.parentComponent != null){
        li.classList.add("component_" + item.parentComponent);
      }
    }

    a.addEventListener('click', (e) => {
      e.preventDefault();
      history.pushState(null, null, `#${id}`);
      handleHashNavigation();
    });

    li.appendChild(a);
    ul.appendChild(li);

    // Store generated ID back to item for ScrollSpy
    item.finalId = id;
  });

  rightPanel.appendChild(ul);

  // Adjust Panel Title
  const panelTitle = document.getElementById('right-panel-title');
  if (panelTitle && dependencyReport) {
    panelTitle.textContent = 'Components';
  }

  // ---------------------------------------------------------
  // SCROLLSPY LOGIC
  // ---------------------------------------------------------


  // Also trigger on scroll for smoother updates
  window.addEventListener('scroll', () => {
    // Throttle could be added here
    checkActiveSection(navItems, ul);
  }, { passive: true });

  // Initial check
  checkActiveSection(navItems, ul);
}

function checkActiveSection(navItems, ul) {
  // Revised Goal: Prioritize elements that are actually "starting" in the view (visual focus).
  // If no element is starting, fall back to the one we are currently "inside" (sticky focus).

  let visualCandidate = null;
  let stickyCandidate = null;

  // "Sweet spot" for an element to be considered the visual active start
  // Since scroll-margin-top is 20px, an element usually lands around 20px.
  // We search for the *first* element appearing in 0px - 150px range.
  const visualTop = 0;
  const visualBottom = 120;

  // Iterate through all items
  for (const item of navItems) {
    const elem = document.getElementById(item.finalId);
    if (!elem) continue;

    const rect = elem.getBoundingClientRect();

    // Check for Visual Candidate (First one wins)
    if (!visualCandidate && rect.top >= visualTop && rect.top <= visualBottom) {
      visualCandidate = item;
    }

    // Check for Sticky Candidate (Last one wins)
    // Anything that has passed the top edge (or is just about to)
    if (rect.top < visualTop + 10) { // +10 tolerance
      stickyCandidate = item;
    }
  }

  // Priority: Visual -> Sticky
  const activeItem = visualCandidate || stickyCandidate;

  // Update UI
  if (activeItem) {
    ul.querySelectorAll('a').forEach(link => link.classList.remove('active'));
    const activeLink = ul.querySelector(`a[href="#${activeItem.finalId}"]`);
    if (activeLink) activeLink.classList.add('active');
  }
}

// Check on initial load
window.addEventListener('load', handleHashNavigation);

// Check on hash changes (if user clicks links on the same page)
window.addEventListener('hashchange', handleHashNavigation);

window.addEventListener('load', addMainNavigation);
window.addEventListener('load', createChangelogOverview);
window.addEventListener('load', createRightPanelNav);
window.addEventListener('load', formatDate);

function formatDate() {
  const monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  // Sucht alle Elemente mit der Klasse .release-date
  const dateElements = document.querySelectorAll('.release-date');

  dateElements.forEach(el => {
    const dateString = el.textContent.trim();
    if (!dateString) return;

    const parts = dateString.split('.');
    if (parts.length !== 3) return;

    const day = parts[0];
    const monthIndex = parseInt(parts[1], 10) - 1;
    const year = parts[2];

    // Nur formatieren, wenn der Monat gültig ist
    if (monthIndex >= 0 && monthIndex <= 11) {
      el.textContent = `${day}. ${monthNames[monthIndex]} ${year}`;
    }
  });
}

// Aufruf beim Laden der Seite
window.addEventListener("load", formatDate);