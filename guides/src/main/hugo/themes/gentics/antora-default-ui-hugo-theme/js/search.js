// Search overlay functionality
(function() {
    const searchToggle = document.querySelector('.search-toggle');
    const searchOverlay = document.getElementById('search-overlay');
    const searchClose = document.querySelector('.search-close');
    const searchBackdrop = document.querySelector('.search-overlay-backdrop');
    const searchInput = document.querySelector('.search-input');
    const categoryFilters = document.querySelectorAll('.category-filter');
    const searchResultsContainer = document.querySelector('.search-results');
    let searchResults = document.querySelectorAll('.search-result-item');
    let currentCategory = 'all';

    // Search index and documents
    let searchIndex = null;
    let searchDocuments = [];
    let isIndexLoaded = false;

    function openSearch() {
        searchOverlay.classList.add('is-open');
        document.body.classList.add('search-open');
        searchToggle.setAttribute('aria-expanded', 'true');
        // Focus search input after animation
        setTimeout(() => searchInput.focus(), 100);
    }

    function closeSearch() {
        searchOverlay.classList.remove('is-open');
        document.body.classList.remove('search-open');
        searchToggle.setAttribute('aria-expanded', 'false');
    }


    async function initializeSearchIndex() {
        try {
            const response = await fetch(searchOverlay.dataset.searchurl);

            if (!response.ok) {
                throw new Error(`Failed to load search data: ${response.status}`);
            }

            const data = await response.json();
            searchDocuments = data;

            // Build Lunr index
            searchIndex = lunr(function () {
                this.ref('url');
                this.field('title', { boost: 10 });
                this.field('content');
                this.field('category', { boost: 5 });
                this.field('description', { boost: 3 });

                data.forEach(doc => {
                    this.add(doc);
                });
            });

            isIndexLoaded = true;
            console.log('Search index loaded with', data.length, 'documents');

            // Update search input placeholder to indicate ready state
            searchInput.placeholder = 'Search documentation...';
            searchInput.disabled = false;

        } catch (error) {
            console.error('Error loading search index:', error);
            searchInput.placeholder = 'Search unavailable';
            searchInput.disabled = true;

            // Show error in results area
            searchResultsContainer.innerHTML = `
                <div class="search-empty">
                    <div class="search-empty-icon">⚠️</div>
                    <p class="search-empty-text">Search index could not be loaded.</p>
                </div>
            `;
        }
    }

    /**
     * Perform search based on query string
     * @param {string} query - The search query entered by user
     * @returns {Array} - Array of search result objects
     */
    function performSearch(query) {
        if (query.length <= 0) {
            return [];
        }

        if (!isIndexLoaded || !searchIndex) {
            console.warn('Search index not loaded yet');
            return [];
        }

        const terms = query.split(/\s+/);
        const wildcardQuery = terms
            .filter(term => term.length > 0)
            .map(term => term.endsWith('*') ? term : term + '*')
            .join(' ');

        const rawResults = searchIndex.search(wildcardQuery);
        let results = [];

        rawResults.forEach(result => {
            const doc = searchDocuments.find(d => d.url === result.ref);
            if (!doc) return;

            // Create a copy to avoid modifying original
            const resultDoc = { ...doc };

            const stemmer = lunr.stemmer;
            const stemmedTerms = terms.map(t => stemmer(new lunr.Token(t)).toString());
            const allTerms = [...new Set([...terms, ...stemmedTerms])];

            const excerpt = getExcerpt(resultDoc.content, allTerms);
            const highlighted = highlightTerms(excerpt, allTerms);
            resultDoc.excerpt = highlighted;

            results.push(resultDoc);
        });

        return results;
    }

    /**
     * Render search results in the DOM
     * @param {Array} results - Array of search result objects
     */
    function renderSearchResults(results) {
        // Clear existing results
        searchResultsContainer.innerHTML = '';

        if (results.length === 0) {
            // Show empty state or keep original results
            searchResultsContainer.innerHTML = `
                <div class="search-empty">
                    <div class="search-empty-icon">🔍</div>
                    <p class="search-empty-text">No results found. Try a different search term.</p>
                </div>
            `;
            return;
        }

        // Render each result
        results.forEach(result => {
            const resultItem = document.createElement('a');
            resultItem.href = result.url;
            resultItem.className = 'search-result-item';
            resultItem.setAttribute('data-category', result.category || 'general');

            resultItem.innerHTML = `
                <div class="search-result-header">
                    <h3 class="search-result-title">${result.title}</h3>
                    <span class="result-category">${result.category || 'General'}</span>
                </div>
                <p class="search-result-description">${result.excerpt}</p>
            `;

            searchResultsContainer.appendChild(resultItem);
        });

        // Update searchResults NodeList after rendering
        searchResults = document.querySelectorAll('.search-result-item');
    }

    /**
     * Debounce function to limit search frequency
     */
    function debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    /**
     * Handle search input changes
     */
    const handleSearch = debounce((query) => {

        // Perform search
        const results = performSearch(query);

        // Render results (if you implemented performSearch)
        renderSearchResults(results);
    }, 300); // Wait 300ms after user stops typing

    // Listen to search input
    searchInput.addEventListener('input', (e) => {
        handleSearch(e.target.value);
    });

    function getExcerpt(content, searchTerms, contextLength = 200) {
        const lowerContent = content.toLowerCase();

        // Find the first matching term's position
        let matchIndex = -1;
        let matchedTerm = '';

        for (const term of searchTerms) {
            const index = lowerContent.indexOf(term.toLowerCase());
            if (index !== -1 && (matchIndex === -1 || index < matchIndex)) {
            matchIndex = index;
            matchedTerm = term;
            }
        }

        if (matchIndex === -1) {
            // No match found, return start of content
            return content.slice(0, contextLength * 2) + '...';
        }

        // Extract surrounding context
        const start = Math.max(0, matchIndex - contextLength);
        const end = Math.min(content.length, matchIndex + matchedTerm.length + contextLength);

        let excerpt = content.slice(start, end);

        // Add ellipses if we're not at the boundaries
        if (start > 0) excerpt = '...' + excerpt;
        if (end < content.length) excerpt = excerpt + '...';

        return excerpt;
        }

        // Optional: highlight the matched terms
        function highlightTerms(text, terms) {
        let result = text;
        for (const term of terms) {
            const regex = new RegExp(`(${term})`, 'gi');
            result = result.replace(regex, '<mark>$1</mark>');
        }
        return result;
    }

    // Open search
    searchToggle.addEventListener('click', openSearch);

    // Close search
    searchClose.addEventListener('click', closeSearch);
    searchBackdrop.addEventListener('click', closeSearch);


    // Close on Escape key
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && searchOverlay.classList.contains('is-open')) {
            closeSearch();
        }
    });

    // Open search with keyboard shortcut (Ctrl/Cmd + K)
    document.addEventListener('keydown', function(e) {
        if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
            e.preventDefault();
            openSearch();
        }
    });

    // Initialize search index on page load
    initializeSearchIndex();

})();
