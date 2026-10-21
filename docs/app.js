/**
 * MirrorLock — Figma Portfolio Theme Controller
 * Smooth navigation, interactive showcase carousel, clipboard actions,
 * and direct download interception modal
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
    const copyBtns = document.querySelectorAll('.copy-btn, .copy-mini-btn');

    copyBtns.forEach(btn => {
      btn.addEventListener('click', async () => {
        const rawText = btn.getAttribute('data-copy-raw');
        const targetId = btn.getAttribute('data-copy-target');
        const codeEl = targetId ? document.getElementById(targetId) : btn.closest('.code-box')?.querySelector('code');
        const text = rawText || (codeEl ? codeEl.textContent.trim() : '');
        if (!text) return;

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

  // --- Direct Download Interception (Promote Curl & Homebrew) ---
  function setupDirectDownloadInterception() {
    const modal = document.getElementById('curl-prompt-modal');
    if (!modal) return;

    const closeBtn = document.getElementById('modal-close-btn');
    const preferCurlBtn = document.getElementById('modal-prefer-curl-btn');
    const preferBrewBtn = document.getElementById('modal-prefer-brew-btn');
    const bypassLink = document.getElementById('modal-bypass-download-link');
    const directLinks = document.querySelectorAll('.direct-link-card');

    let pendingDownloadUrl = '';

    function openModal(url) {
      pendingDownloadUrl = url;
      if (bypassLink) {
        bypassLink.setAttribute('data-target-url', url);
      }
      modal.classList.remove('hidden');
    }

    function closeModal() {
      modal.classList.add('hidden');
      pendingDownloadUrl = '';
    }

    directLinks.forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        const url = link.getAttribute('href');
        openModal(url);
      });
    });

    if (closeBtn) {
      closeBtn.addEventListener('click', closeModal);
    }

    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        closeModal();
      }
    });

    // Option 1: Prefer Curl
    if (preferCurlBtn) {
      preferCurlBtn.addEventListener('click', async () => {
        const curlTab = document.querySelector('.install-tab-btn[data-tab="curl"]');
        if (curlTab) curlTab.click();

        const installSec = document.getElementById('install');
        if (installSec) {
          installSec.scrollIntoView({ behavior: 'smooth' });
        }

        const curlCmd = 'curl -fsSL https://raw.githubusercontent.com/shubhransh-gupta/mirrorLock/main/scripts/install.sh | bash';
        try {
          await navigator.clipboard.writeText(curlCmd);
          preferCurlBtn.innerHTML = '<span>✓ Copied! Switching...</span>';
          setTimeout(() => {
            preferCurlBtn.innerHTML = '<span>⚡ Copy Curl Command &amp; Run</span>';
            closeModal();
          }, 800);
        } catch (err) {
          closeModal();
        }
      });
    }

    // Option 2: Prefer Homebrew
    if (preferBrewBtn) {
      preferBrewBtn.addEventListener('click', async () => {
        const brewTab = document.querySelector('.install-tab-btn[data-tab="brew"]');
        if (brewTab) brewTab.click();

        const installSec = document.getElementById('install');
        if (installSec) {
          installSec.scrollIntoView({ behavior: 'smooth' });
        }

        const brewCmd = 'brew install --cask shubhransh-gupta/tap/mirrorlock';
        try {
          await navigator.clipboard.writeText(brewCmd);
          preferBrewBtn.innerHTML = '<span>✓ Copied! Switching...</span>';
          setTimeout(() => {
            preferBrewBtn.innerHTML = '<span>🍺 Copy Homebrew Command</span>';
            closeModal();
          }, 800);
        } catch (err) {
          closeModal();
        }
      });
    }

    // Option 3: Continue direct download
    if (bypassLink) {
      bypassLink.addEventListener('click', (e) => {
        e.preventDefault();
        const url = bypassLink.getAttribute('data-target-url') || pendingDownloadUrl;
        closeModal();
        if (url && url !== '#') {
          window.location.href = url;
        }
      });
    }
  }

  // --- Vertical Dock Active Link Tracking on Scroll ---
  function setupDockScrollSpy() {
    const dockLinks = document.querySelectorAll('.dock-item');
    const sections = ['hero', 'features', 'how', 'unlock', 'install'];

    function onScroll() {
      const scrollPos = window.scrollY + 220;

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
    setupDirectDownloadInterception();
    setupDockScrollSpy();

    const yearEl = document.getElementById('year');
    if (yearEl) yearEl.textContent = new Date().getFullYear();
  });
})();
