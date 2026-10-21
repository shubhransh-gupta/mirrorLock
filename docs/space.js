/**
 * Cosmic Galaxy Background Engine
 * Twinkling stars, shooting meteors, and atmospheric glow
 */
(function() {
  'use strict';

  const canvas = document.getElementById('space-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');

  let width = 0;
  let height = 0;
  let stars = [];
  let meteors = [];

  function resize() {
    width = canvas.width = window.innerWidth;
    height = canvas.height = window.innerHeight;
    initStars();
  }

  function initStars() {
    stars = [];
    // Adjust star count based on screen size
    const count = Math.floor((width * height) / 3000);
    for (let i = 0; i < count; i++) {
      stars.push({
        x: Math.random() * width,
        y: Math.random() * height,
        radius: Math.random() * 1.5 + 0.3,
        alpha: Math.random() * 0.8 + 0.2,
        twinkleSpeed: (Math.random() * 0.02 + 0.005) * (Math.random() > 0.5 ? 1 : -1),
        color: Math.random() > 0.8 ? '#a5b4fc' : (Math.random() > 0.6 ? '#7dd3fc' : '#ffffff')
      });
    }
  }

  function spawnMeteor() {
    // Meteors travel from top-right to bottom-left or top to bottom-angle
    const startX = Math.random() * width * 1.2;
    const startY = Math.random() * (height * 0.4);
    const length = Math.random() * 120 + 80;
    const speed = Math.random() * 8 + 6;
    const angle = (Math.PI / 4) + (Math.random() * 0.2 - 0.1); // ~45 degrees

    meteors.push({
      x: startX,
      y: startY,
      length: length,
      speed: speed,
      dx: -Math.cos(angle) * speed,
      dy: Math.sin(angle) * speed,
      opacity: 1,
      decay: Math.random() * 0.015 + 0.01,
      color: Math.random() > 0.4 ? '#38bdf8' : '#e0e7ff',
      width: Math.random() * 1.8 + 1.2
    });
  }

  // Spawn meteors periodically
  let lastMeteorTime = 0;
  function maybeSpawnMeteor(time) {
    if (time - lastMeteorTime > 1600 + Math.random() * 2400) {
      spawnMeteor();
      lastMeteorTime = time;
    }
  }

  function draw(time) {
    ctx.clearRect(0, 0, width, height);

    // 1. Draw twinkling stars
    for (let i = 0; i < stars.length; i++) {
      const star = stars[i];
      star.alpha += star.twinkleSpeed;
      if (star.alpha > 0.95 || star.alpha < 0.15) {
        star.twinkleSpeed = -star.twinkleSpeed;
      }

      ctx.beginPath();
      ctx.arc(star.x, star.y, star.radius, 0, Math.PI * 2);
      ctx.fillStyle = star.color;
      ctx.globalAlpha = Math.max(0.1, Math.min(1, star.alpha));
      ctx.fill();
    }

    // 2. Update and draw meteors
    maybeSpawnMeteor(time);

    for (let i = meteors.length - 1; i >= 0; i--) {
      const m = meteors[i];
      m.x += m.dx;
      m.y += m.dy;
      m.opacity -= m.decay;

      if (m.opacity <= 0 || m.x < -200 || m.y > height + 200) {
        meteors.splice(i, 1);
        continue;
      }

      // Draw meteor streak
      const tailX = m.x - m.dx * (m.length / m.speed);
      const tailY = m.y - m.dy * (m.length / m.speed);

      const grad = ctx.createLinearGradient(m.x, m.y, tailX, tailY);
      grad.addColorStop(0, m.color);
      grad.addColorStop(0.2, 'rgba(56, 189, 248, 0.7)');
      grad.addColorStop(1, 'rgba(56, 189, 248, 0)');

      ctx.beginPath();
      ctx.moveTo(m.x, m.y);
      ctx.lineTo(tailX, tailY);
      ctx.strokeStyle = grad;
      ctx.lineWidth = m.width;
      ctx.lineCap = 'round';
      ctx.globalAlpha = Math.max(0, m.opacity);
      ctx.stroke();

      // Meteor head glowing point
      ctx.beginPath();
      ctx.arc(m.x, m.y, m.width * 1.5, 0, Math.PI * 2);
      ctx.fillStyle = '#ffffff';
      ctx.globalAlpha = Math.max(0, m.opacity);
      ctx.fill();
    }

    ctx.globalAlpha = 1;
    requestAnimationFrame(draw);
  }

  window.addEventListener('resize', resize);
  resize();
  requestAnimationFrame(draw);
})();
