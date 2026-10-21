/**
 * MirrorLock — Main Interactive Controller
 */
(function() {
  'use strict';

  // Setup tab switcher in installation section
  function setupTabs() {
    const tabs = document.querySelectorAll('.tab-btn');
    const panes = document.querySelectorAll('.install-pane');

    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        const target = tab.getAttribute('data-tab');

        tabs.forEach(t => t.classList.remove('active'));
        panes.forEach(p => p.classList.remove('active'));

        tab.classList.add('active');
        const activePane = document.getElementById('pane-' + target);
        if (activePane) activePane.classList.add('active');
      });
    });
  }

  // Setup copy-to-clipboard buttons
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
          const originalText = btn.innerHTML;
          btn.innerHTML = '<span>✓ Copied!</span>';
          btn.classList.add('copied');

          setTimeout(() => {
            btn.innerHTML = originalText;
            btn.classList.remove('copied');
          }, 2000);
        } catch (err) {
          btn.textContent = 'Copied!';
          setTimeout(() => { btn.textContent = 'Copy'; }, 2000);
        }
      });
    });
  }

  // Auto-update footer year
  function setupYear() {
    const yearEl = document.getElementById('year');
    if (yearEl) {
      yearEl.textContent = new Date().getFullYear();
    }
  }

  document.addEventListener('DOMContentLoaded', () => {
    setupTabs();
    setupCopyButtons();
    setupYear();
  });
})();
