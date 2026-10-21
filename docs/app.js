/**
 * MirrorLock — Cybernetic UI & Simulator Engine
 * Inspired by Total Recall / High-tech Cyberpunk Sci-Fi
 */

(function () {
  'use strict';

  // --- Cybernetic Sound Synthesizer (Web Audio API) ---
  class CyberAudio {
    constructor() {
      this.ctx = null;
      this.enabled = false; // default off until user opts in or interacts
    }

    init() {
      if (!this.ctx && typeof AudioContext !== 'undefined') {
        const AudioCtx = window.AudioContext || window.webkitAudioContext;
        this.ctx = new AudioCtx();
      }
      if (this.ctx && this.ctx.state === 'suspended') {
        this.ctx.resume();
      }
    }

    toggle() {
      this.init();
      this.enabled = !this.enabled;
      return this.enabled;
    }

    playBeep(freq = 880, type = 'sine', duration = 0.08, gainVal = 0.08) {
      if (!this.enabled || !this.ctx) return;
      try {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = type;
        osc.frequency.setValueAtTime(freq, this.ctx.currentTime);
        gain.gain.setValueAtTime(gainVal, this.ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.0001, this.ctx.currentTime + duration);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start();
        osc.stop(this.ctx.currentTime + duration);
      } catch (e) {
        // audio fail silent
      }
    }

    playIntruderAlert() {
      if (!this.enabled || !this.ctx) return;
      try {
        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(440, now);
        osc.frequency.linearRampToValueAtTime(220, now + 0.25);
        gain.gain.setValueAtTime(0.15, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.25);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start(now);
        osc.stop(now + 0.25);
      } catch (e) {}
    }

    playUnlockChime() {
      if (!this.enabled || !this.ctx) return;
      try {
        const notes = [523.25, 659.25, 783.99, 1046.5]; // C5, E5, G5, C6
        notes.forEach((freq, idx) => {
          const osc = this.ctx.createOscillator();
          const gain = this.ctx.createGain();
          const start = this.ctx.currentTime + idx * 0.06;
          osc.type = 'triangle';
          osc.frequency.setValueAtTime(freq, start);
          gain.gain.setValueAtTime(0.08, start);
          gain.gain.exponentialRampToValueAtTime(0.0001, start + 0.2);
          osc.connect(gain);
          gain.connect(this.ctx.destination);
          osc.start(start);
          osc.stop(start + 0.2);
        });
      } catch (e) {}
    }

    playClick() {
      this.playBeep(1200, 'square', 0.03, 0.03);
    }
  }

  const audio = new CyberAudio();

  // --- Sound & CRT Scanlines Toggles ---
  function setupToggles() {
    const sfxBtn = document.getElementById('toggle-sfx');
    const crtBtn = document.getElementById('toggle-crt');
    const crtOverlay = document.getElementById('crt-scanline-layer');

    if (sfxBtn) {
      sfxBtn.addEventListener('click', () => {
        const active = audio.toggle();
        sfxBtn.classList.toggle('active', active);
        const label = sfxBtn.querySelector('.toggle-label');
        if (label) label.textContent = active ? 'SFX: ON' : 'SFX: MUTED';
        if (active) audio.playBeep(880, 'sine', 0.1);
      });
    }

    if (crtBtn && crtOverlay) {
      crtBtn.addEventListener('click', () => {
        const isOff = crtOverlay.classList.toggle('crt-hidden');
        crtBtn.classList.toggle('active', !isOff);
        const label = crtBtn.querySelector('.toggle-label');
        if (label) label.textContent = isOff ? 'CRT: OFF' : 'CRT: ON';
        audio.playClick();
      });
    }
  }

  // --- Live HUD Simulator ---
  function setupSimulator() {
    const simScreen = document.getElementById('sim-screen');
    const simLockOverlay = document.getElementById('sim-lock-overlay');
    const simAlertBox = document.getElementById('sim-alert-box');
    const simStatusText = document.getElementById('sim-status-indicator');
    const simStateBadge = document.getElementById('sim-state-badge');
    const simIntruderBtn = document.getElementById('sim-trigger-intruder');
    const simUnlockBtn = document.getElementById('sim-trigger-unlock');
    const simToggleLockBtn = document.getElementById('sim-trigger-lock');

    let isLocked = true;
    let alertTimeout = null;

    function triggerIntruderAlert() {
      if (!isLocked) return;
      audio.playIntruderAlert();

      if (simAlertBox) {
        simAlertBox.classList.remove('hidden');
        simAlertBox.classList.add('flash-alert');
      }
      if (simScreen) {
        simScreen.classList.add('screen-alarm');
      }

      clearTimeout(alertTimeout);
      alertTimeout = setTimeout(() => {
        if (simAlertBox) {
          simAlertBox.classList.remove('flash-alert');
          simAlertBox.classList.add('hidden');
        }
        if (simScreen) {
          simScreen.classList.remove('screen-alarm');
        }
      }, 1600);
    }

    function unlockSystem() {
      if (!isLocked) return;
      audio.playUnlockChime();
      isLocked = false;

      if (simLockOverlay) {
        simLockOverlay.classList.add('unlocked');
      }
      if (simAlertBox) {
        simAlertBox.classList.add('hidden');
      }
      if (simScreen) {
        simScreen.classList.remove('screen-alarm');
      }
      if (simStatusText) {
        simStatusText.textContent = 'SYSTEM UNLOCKED // INPUTS ACCESSIBLE';
        simStatusText.classList.add('text-unlocked');
      }
      if (simStateBadge) {
        simStateBadge.textContent = 'STANDBY';
        simStateBadge.classList.remove('badge-locked');
        simStateBadge.classList.add('badge-unlocked');
      }
      if (simToggleLockBtn) {
        simToggleLockBtn.innerHTML = '<span class="key-icon">🔒</span> ENGAGE LOCK (⌘⇧M)';
      }
    }

    function lockSystem() {
      if (isLocked) return;
      audio.playBeep(440, 'triangle', 0.15);
      isLocked = true;

      if (simLockOverlay) {
        simLockOverlay.classList.remove('unlocked');
      }
      if (simStatusText) {
        simStatusText.textContent = 'MIRRORLOCK ACTIVE // INPUTS SEVERED';
        simStatusText.classList.remove('text-unlocked');
      }
      if (simStateBadge) {
        simStateBadge.textContent = 'DEFENSE ARMED';
        simStateBadge.classList.add('badge-locked');
        simStateBadge.classList.remove('badge-unlocked');
      }
      if (simToggleLockBtn) {
        simToggleLockBtn.innerHTML = '<span class="key-icon">⚡</span> DISENGAGE SHIELD';
      }
    }

    // Interactive clicks on the screen trigger intruder alert
    if (simScreen) {
      simScreen.addEventListener('click', (e) => {
        if (e.target.closest('.sim-controls') || e.target.closest('button')) return;
        if (isLocked) {
          triggerIntruderAlert();
        }
      });
    }

    if (simIntruderBtn) {
      simIntruderBtn.addEventListener('click', () => {
        if (!isLocked) lockSystem();
        setTimeout(triggerIntruderAlert, 100);
      });
    }

    if (simUnlockBtn) {
      simUnlockBtn.addEventListener('click', () => {
        unlockSystem();
      });
    }

    if (simToggleLockBtn) {
      simToggleLockBtn.addEventListener('click', () => {
        if (isLocked) {
          unlockSystem();
        } else {
          lockSystem();
        }
      });
    }

    // Code Stream Animation in Simulator Terminal
    simulateCodeStream();
  }

  // --- Real-time Code Stream Simulator ---
  function simulateCodeStream() {
    const codeContainer = document.getElementById('sim-code-stream');
    if (!codeContainer) return;

    const codeLines = [
      '// Autonomous Agent: Claude-Code-09 [REKALL PIPELINE]',
      'const kernelTap = await System.CGEventTap.create({',
      '  events: [KEY_DOWN, MOUSE_MOVE, TOUCH_GESTURE],',
      '  intercept: EventDisposition.DROP_SILENTLY',
      '});',
      'const displayAssertion = IOKit.createPowerAssertion({',
      '  type: kIOPMAssertionTypePreventUserIdleDisplaySleep,',
      '  level: kIOPMAssertionLevelOn',
      '});',
      'console.log("[REKALL_AGENT] Compiling autonomous refactor...");',
      'await ModelPipeline.executeStage("AST_OPTIMIZE", { workers: 8 });',
      '[OK] 24 modules refactored with zero human tampering.',
      'console.log("[TELEMETRY] Screen visible. System untouched.");',
      '// Awaiting next neural iteration...'
    ];

    let lineIndex = 0;
    setInterval(() => {
      const line = document.createElement('div');
      line.className = 'sim-code-line';
      if (codeLines[lineIndex].startsWith('//')) line.classList.add('comment');
      else if (codeLines[lineIndex].includes('console') || codeLines[lineIndex].includes('[OK]')) line.classList.add('highlight');
      else if (codeLines[lineIndex].includes('await') || codeLines[lineIndex].includes('const')) line.classList.add('keyword');
      
      line.textContent = codeLines[lineIndex];
      codeContainer.appendChild(line);

      // Keep max 14 lines
      if (codeContainer.children.length > 14) {
        codeContainer.removeChild(codeContainer.firstChild);
      }

      lineIndex = (lineIndex + 1) % codeLines.length;
    }, 1800);
  }

  // --- Install Terminal Tabs & Copy ---
  function setupInstallTabs() {
    const tabs = document.querySelectorAll('.tab-btn');
    const panes = document.querySelectorAll('.install-pane');

    tabs.forEach((tab) => {
      tab.addEventListener('click', () => {
        audio.playClick();
        const targetId = tab.dataset.tab;

        tabs.forEach((t) => t.classList.remove('active'));
        panes.forEach((p) => p.classList.remove('active'));

        tab.classList.add('active');
        const targetPane = document.getElementById(`pane-${targetId}`);
        if (targetPane) targetPane.classList.add('active');
      });
    });

    const copyButtons = document.querySelectorAll('.btn-copy-code');
    copyButtons.forEach((btn) => {
      btn.addEventListener('click', async () => {
        const codeElement = btn.closest('.code-box')?.querySelector('code');
        if (!codeElement) return;

        const text = codeElement.textContent.trim();
        try {
          await navigator.clipboard.writeText(text);
          audio.playBeep(980, 'sine', 0.08);

          const originalText = btn.dataset.originalText || btn.innerHTML;
          btn.dataset.originalText = originalText;
          btn.innerHTML = '✓ COPIED // BUFFER READY';
          btn.classList.add('copied');

          setTimeout(() => {
            btn.innerHTML = originalText;
            btn.classList.remove('copied');
          }, 2000);
        } catch (err) {
          // fallback
          btn.textContent = 'FAILED';
        }
      });
    });
  }

  // --- Telemetry Clock & Coordinates ---
  function setupTelemetry() {
    const timeEl = document.getElementById('telemetry-time');
    const uptimeEl = document.getElementById('telemetry-uptime');
    const startTime = Date.now();

    function update() {
      if (timeEl) {
        const now = new Date();
        timeEl.textContent = now.toTimeString().split(' ')[0] + ' UTC' + (now.getTimezoneOffset() <= 0 ? '+' : '-') + Math.abs(now.getTimezoneOffset() / 60);
      }
      if (uptimeEl) {
        const secs = Math.floor((Date.now() - startTime) / 1000);
        const mins = Math.floor(secs / 60);
        uptimeEl.textContent = `UPTIME: ${String(mins).padStart(2, '0')}:${String(secs % 60).padStart(2, '0')}`;
      }
    }
    update();
    setInterval(update, 1000);
  }

  // --- Smooth Scroll Sound Feedback ---
  function setupNavLinks() {
    document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
      anchor.addEventListener('click', function (e) {
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
          audio.playClick();
        }
      });
    });
  }

  // --- Initialize Everything on DOM Load ---
  document.addEventListener('DOMContentLoaded', () => {
    setupToggles();
    setupSimulator();
    setupInstallTabs();
    setupTelemetry();
    setupNavLinks();

    // Year update in footer
    const yearEl = document.getElementById('year');
    if (yearEl) yearEl.textContent = new Date().getFullYear();
  });
})();
