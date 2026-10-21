/**
 * MirrorLock — Figma Portfolio Theme Controller
 * Smooth navigation, interactive showcase carousel, and clipboard actions
 */
(function () {
  'use strict';

  // --- Showcase Card Deck Selector ---
  function setupShowcaseDeck() {
    const cards = document.querySelectorAll('.showcase-card');
    const tabs = document.querySelectorAll('.showcase-tab');

    if (!cards.length) return;

    function activateCard(index) {
      cards.forEach((card, i) => {
        card.classList.toggle('active', i === index);
      });
      tabs.forEach((tab, i) => {
        tab.classList.toggle('active', i === index);
      });
    }

    tabs.forEach((tab, i) => {
      tab.addEventListener('click', () => activateCard(i));
    });

    cards.forEach((card, i) => {
      card.addEventListener('click', () => activateCard(i));
    });
  }

  // --- Installation Tabs ---
  function setupInstallTabs() {
    const tabBtns = document.querySelectorAll('.install-tab-btn');
    const panes = document.querySelectorAll('.install-pane');

    tabBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        const targetId = btn.getAttribute('data-tab');

        tabBtns.forEach(b => b.classList.remove('active'));
        panes.forEach(p => p.classList.remove('active'));

        btn.classList.add('active');
        const activePane = document.getElementById('pane-' + targetId);
        if (activePane) activePane.classList.add('active');
      });
    });
  }

  // --- Copy to Clipboard ---
  function setupCopyButtons() {
    const copyBtns = document.querySelectorAll('.copy-btn');

    copyBtns.forEach(btn => {
      btn.addEventListener('click', async () => {
        const targetId = btn.getAttribute('data-copy-target');
        const codeEl = targetId ? document.getElementById(targetId) : btn.closest('.code-box')?.querySelector('code');
        if (!codeEl) return;

        const text = codeEl.textContent.trim();
        try {
          await navigator.clipboard.writeText(text);
          const originalHTML = btn.innerHTML;
          btn.innerHTML = '<span>✓ Copied</span>';
          btn.classList.add('copied');

          setTimeout(() => {
            btn.innerHTML = originalHTML;
            btn.classList.remove('copied');
          }, 2000);
        } catch (err) {
          btn.textContent = 'Copied!';
          setTimeout(() => { btn.textContent = 'Copy'; }, 2000);
        }
      });
    });
  }

  // --- Vertical Dock Active Link Tracking on Scroll ---
  function setupDockScrollSpy() {
    const dockLinks = document.querySelectorAll('.dock-item');
    const sections = ['hero', 'features', 'how', 'unlock', 'install'];

    function onScroll() {
      const scrollPos = window.scrollY + 200;

      for (let i = sections.length - 1; i >= 0; i--) {
        const section = document.getElementById(sections[i]);
        if (section && section.offsetTop <= scrollPos) {
          dockLinks.forEach(link => {
            link.classList.toggle('active', link.getAttribute('href') === '#' + sections[i]);
          });
          break;
        }
      }
    }

    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  // --- Initialize on DOM ready ---
  document.addEventListener('DOMContentLoaded', () => {
    setupShowcaseDeck();
    setupInstallTabs();
    setupCopyButtons();
    setupDockScrollSpy();

    const yearEl = document.getElementById('year');
    if (yearEl) yearEl.textContent = new Date().getFullYear();
  });
})();
