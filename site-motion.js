(function () {
  "use strict";

  if (window.__VYPERIA_MOTION_V2__) return;
  window.__VYPERIA_MOTION_V2__ = true;

  var style = document.createElement('style');
  style.id = 'vyperia-motion-v2';
  style.textContent = "\n:root {\n  --motion-v2-x: 50%;\n  --motion-v2-y: 24%;\n  --motion-v2-rx: 0deg;\n  --motion-v2-ry: 0deg;\n  --motion-v2-ease: cubic-bezier(0.16, 1, 0.3, 1);\n  --motion-v2-soft: cubic-bezier(0.22, 1, 0.36, 1);\n}\n\nbody.motion-v2-ready {\n  --ambientA: 0.66;\n}\n\n.motion-v2-layer {\n  position: fixed;\n  inset: 0;\n  z-index: 0;\n  overflow: hidden;\n  pointer-events: none;\n  contain: strict;\n}\n\n.motion-v2-layer::before {\n  position: absolute;\n  inset: -20%;\n  content: \"\";\n  opacity: 0.72;\n  background:\n    radial-gradient(32% 30% at var(--motion-v2-x) var(--motion-v2-y), rgba(102, 227, 255, 0.15), transparent 72%),\n    radial-gradient(30% 42% at 82% 76%, rgba(167, 139, 250, 0.14), transparent 72%),\n    radial-gradient(28% 36% at 8% 82%, rgba(66, 108, 255, 0.1), transparent 72%);\n  filter: blur(20px) saturate(115%);\n  transition: background 800ms var(--motion-v2-soft);\n  animation: motionV2Breath 14s ease-in-out infinite alternate;\n}\n\n.motion-v2-layer::after {\n  position: absolute;\n  inset: 0;\n  content: \"\";\n  opacity: 0.12;\n  background-image:\n    linear-gradient(115deg, transparent 0 46%, rgba(255, 255, 255, 0.06) 50%, transparent 54%),\n    repeating-linear-gradient(0deg, rgba(255, 255, 255, 0.015) 0 1px, transparent 1px 4px);\n  background-size: 100% 100%, 100% 5px;\n  mix-blend-mode: screen;\n  animation: motionV2Scan 12s linear infinite;\n}\n\n.motion-v2-orb {\n  position: absolute;\n  width: var(--orb-size);\n  height: var(--orb-size);\n  left: var(--orb-x);\n  top: var(--orb-y);\n  border-radius: 50%;\n  opacity: var(--orb-opacity);\n  background: var(--orb-color);\n  filter: blur(var(--orb-blur));\n  transform: translate3d(-50%, -50%, 0);\n  animation: motionV2Orb var(--orb-duration) ease-in-out var(--orb-delay) infinite alternate;\n}\n\n.motion-v2-card {\n  --motion-v2-rx: 0deg;\n  --motion-v2-ry: 0deg;\n  --motion-v2-card-x: 50%;\n  --motion-v2-card-y: 50%;\n  position: relative;\n  isolation: isolate;\n  transform-style: preserve-3d;\n  transition:\n    transform 520ms var(--motion-v2-ease),\n    border-color 300ms ease,\n    box-shadow 520ms var(--motion-v2-ease),\n    filter 320ms ease;\n}\n\n.motion-v2-card > *:not(.motion-v2-sheen) {\n  position: relative;\n  z-index: 1;\n}\n\n.motion-v2-card .motion-v2-sheen {\n  position: absolute;\n  inset: 0;\n  z-index: 0;\n  overflow: hidden;\n  pointer-events: none;\n  border-radius: inherit;\n  opacity: 0;\n  background:\n    radial-gradient(circle at var(--motion-v2-card-x) var(--motion-v2-card-y), rgba(255, 255, 255, 0.16), transparent 28%),\n    linear-gradient(120deg, transparent 20%, rgba(102, 227, 255, 0.075) 48%, transparent 72%);\n  transition: opacity 360ms ease;\n}\n\n.motion-v2-card .motion-v2-sheen::after {\n  position: absolute;\n  top: -30%;\n  bottom: -30%;\n  left: -35%;\n  width: 28%;\n  content: \"\";\n  opacity: 0.34;\n  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.32), transparent);\n  transform: rotate(16deg) translateX(-250%);\n}\n\n.motion-v2-card:hover {\n  border-color: color-mix(in srgb, var(--ac) 36%, rgba(255, 255, 255, 0.1));\n  box-shadow:\n    0 22px 60px rgba(0, 0, 0, 0.3),\n    0 0 34px rgba(108, 92, 255, 0.1);\n  filter: saturate(1.06);\n}\n\n.motion-v2-card:hover .motion-v2-sheen {\n  opacity: 1;\n}\n\n.motion-v2-card:hover .motion-v2-sheen::after {\n  animation: motionV2Sheen 900ms var(--motion-v2-ease) both;\n}\n\n.motion-v2-tilt {\n  transform:\n    perspective(1200px)\n    rotateX(var(--motion-v2-rx))\n    rotateY(var(--motion-v2-ry))\n    translate3d(0, 0, 0);\n  will-change: transform;\n}\n\n.motion-v2-tilt:hover {\n  transform:\n    perspective(1200px)\n    rotateX(var(--motion-v2-rx))\n    rotateY(var(--motion-v2-ry))\n    translate3d(0, -6px, 0);\n}\n\n.motion-v2-card img {\n  transition:\n    transform 700ms var(--motion-v2-ease),\n    filter 500ms var(--motion-v2-ease);\n}\n\n.motion-v2-card:hover > img,\n.motion-v2-card:hover .script-card__thumb,\n.motion-v2-card:hover .private-server-card__icon,\n.motion-v2-card:hover .pinned-game-card__image,\n.motion-v2-card:hover .bootstrapper-card__logo {\n  transform: scale(1.045) translateZ(12px);\n  filter: saturate(1.12) brightness(1.06);\n}\n\n.brand-icon {\n  animation: motionV2BrandFloat 5s ease-in-out infinite;\n}\n\n.brand-icon::before {\n  position: absolute;\n  inset: -45%;\n  content: \"\";\n  border-radius: inherit;\n  background: conic-gradient(from 0deg, transparent, rgba(102, 227, 255, 0.45), transparent 32%);\n  animation: motionV2Spin 7s linear infinite;\n}\n\n.brand-icon::after {\n  position: absolute;\n  inset: 1px;\n  content: \"\";\n  border: 1px solid rgba(255, 255, 255, 0.12);\n  border-radius: inherit;\n  pointer-events: none;\n}\n\n.brand-icon img {\n  position: relative;\n  z-index: 1;\n}\n\n.tb {\n  isolation: isolate;\n}\n\n.tb::before {\n  position: absolute;\n  inset: 1px;\n  z-index: -1;\n  content: \"\";\n  border-radius: inherit;\n  opacity: 0;\n  background: linear-gradient(100deg, rgba(102, 227, 255, 0.14), rgba(167, 139, 250, 0.14), transparent);\n  transform: translateX(-105%);\n  transition: opacity 300ms ease, transform 650ms var(--motion-v2-ease);\n}\n\n.tb:hover::before,\n.tb.act::before {\n  opacity: 1;\n  transform: translateX(0);\n}\n\n.tb.act::after {\n  box-shadow: 0 0 12px var(--ac), 0 0 26px rgba(167, 139, 250, 0.55);\n  animation: motionV2NavPulse 2.2s ease-in-out infinite;\n}\n\n.hero__actions > *,\n.as-actions > *,\n.btn,\nbutton,\na {\n  transition-timing-function: var(--motion-v2-ease);\n}\n\n.hero__actions > *,\n.as-actions > *,\n.btn {\n  position: relative;\n  overflow: hidden;\n}\n\n.hero__actions > *::after,\n.btn::after {\n  position: absolute;\n  inset: -80% -30%;\n  content: \"\";\n  opacity: 0;\n  background: linear-gradient(115deg, transparent 42%, rgba(255, 255, 255, 0.28) 50%, transparent 58%);\n  transform: translateX(-65%) rotate(8deg);\n  transition: opacity 240ms ease;\n}\n\n.hero__actions > *:hover::after,\n.btn:hover::after {\n  opacity: 1;\n  animation: motionV2ButtonSweep 900ms var(--motion-v2-ease) both;\n}\n\n.motion-v2-ripple {\n  position: absolute;\n  width: 14px;\n  height: 14px;\n  pointer-events: none;\n  border-radius: 50%;\n  background: rgba(255, 255, 255, 0.46);\n  transform: translate(-50%, -50%) scale(0);\n  animation: motionV2Ripple 720ms ease-out forwards;\n}\n\n.motion-v2-scroll {\n  position: fixed;\n  top: 0;\n  left: 0;\n  z-index: 10000;\n  width: 100%;\n  height: 2px;\n  pointer-events: none;\n  background: linear-gradient(90deg, #58d7ff, #a78bfa 48%, #72f3b6);\n  box-shadow: 0 0 18px rgba(102, 227, 255, 0.7);\n  transform: scaleX(0);\n  transform-origin: left center;\n}\n\n.motion-v2-cursor {\n  position: fixed;\n  top: 0;\n  left: 0;\n  z-index: 10001;\n  width: 28px;\n  height: 28px;\n  pointer-events: none;\n  border: 1px solid rgba(172, 228, 255, 0.7);\n  border-radius: 50%;\n  opacity: 0;\n  mix-blend-mode: screen;\n  transform: translate3d(-100px, -100px, 0);\n  transition:\n    width 180ms var(--motion-v2-ease),\n    height 180ms var(--motion-v2-ease),\n    border-color 180ms ease,\n    opacity 180ms ease;\n}\n\n.motion-v2-cursor::before,\n.motion-v2-cursor::after {\n  position: absolute;\n  top: 50%;\n  left: 50%;\n  content: \"\";\n  transform: translate(-50%, -50%);\n}\n\n.motion-v2-cursor::before {\n  width: 4px;\n  height: 4px;\n  border-radius: 50%;\n  background: #fff;\n  box-shadow: 0 0 14px #66e3ff, 0 0 28px rgba(167, 139, 250, 0.85);\n}\n\n.motion-v2-cursor::after {\n  width: 42px;\n  height: 42px;\n  border: 1px solid rgba(102, 227, 255, 0.13);\n  border-radius: 50%;\n}\n\n.motion-v2-cursor.is-visible {\n  opacity: 0.78;\n}\n\n.motion-v2-cursor.is-pressing {\n  width: 42px;\n  height: 42px;\n  border-color: #fff;\n}\n\n.motion-v2-page-surge {\n  animation: motionV2PageSurge 620ms var(--motion-v2-ease) both !important;\n}\n\n.motion-v2-nav-burst {\n  position: fixed;\n  z-index: 10002;\n  width: 14px;\n  height: 14px;\n  pointer-events: none;\n  border: 1px solid rgba(162, 229, 255, 0.9);\n  border-radius: 50%;\n  transform: translate(-50%, -50%) scale(0);\n  animation: motionV2NavBurst 700ms var(--motion-v2-ease) forwards;\n}\n\n.motion-v2-live {\n  animation: motionV2Live 900ms var(--motion-v2-ease);\n}\n\n@keyframes motionV2Breath {\n  0% { transform: scale(1) translate3d(-1%, -1%, 0); }\n  100% { transform: scale(1.08) translate3d(1.5%, 1%, 0); }\n}\n\n@keyframes motionV2Scan {\n  to { background-position: 100% 0, 0 100%; }\n}\n\n@keyframes motionV2Orb {\n  0% { transform: translate3d(-50%, -50%, 0) scale(0.92); }\n  100% { transform: translate3d(calc(-50% + var(--orb-drift)), calc(-50% - var(--orb-rise)), 0) scale(1.12); }\n}\n\n@keyframes motionV2Sheen {\n  to { transform: rotate(16deg) translateX(600%); }\n}\n\n@keyframes motionV2Spin {\n  to { transform: rotate(360deg); }\n}\n\n@keyframes motionV2BrandFloat {\n  0%, 100% { transform: translate3d(0, 0, 0) rotate(0); }\n  50% { transform: translate3d(0, -3px, 0) rotate(-1deg); }\n}\n\n@keyframes motionV2NavPulse {\n  0%, 100% { filter: brightness(1); }\n  50% { filter: brightness(1.45); }\n}\n\n@keyframes motionV2ButtonSweep {\n  to { transform: translateX(65%) rotate(8deg); }\n}\n\n@keyframes motionV2Ripple {\n  to { opacity: 0; transform: translate(-50%, -50%) scale(30); }\n}\n\n@keyframes motionV2PageSurge {\n  0% { opacity: 0.62; transform: translate3d(0, 12px, 0) scale(0.992); filter: blur(2px) saturate(0.86); }\n  55% { opacity: 1; transform: translate3d(0, -2px, 0) scale(1.004); filter: blur(0) saturate(1.08); }\n  100% { opacity: 1; transform: none; filter: none; }\n}\n\n@keyframes motionV2NavBurst {\n  100% { opacity: 0; transform: translate(-50%, -50%) scale(18); }\n}\n\n@keyframes motionV2Live {\n  0% { filter: brightness(1); }\n  35% { filter: brightness(1.3) saturate(1.3); }\n  100% { filter: brightness(1); }\n}\n\n@media (max-width: 760px) {\n  .motion-v2-layer::after {\n    opacity: 0.06;\n  }\n\n  .motion-v2-cursor,\n  .motion-v2-tilt {\n    transform: none !important;\n  }\n\n  .motion-v2-card:hover {\n    transform: translate3d(0, -3px, 0);\n  }\n\n  .motion-v2-card:hover > img,\n  .motion-v2-card:hover .script-card__thumb,\n  .motion-v2-card:hover .private-server-card__icon,\n  .motion-v2-card:hover .pinned-game-card__image,\n  .motion-v2-card:hover .bootstrapper-card__logo {\n    transform: scale(1.025);\n  }\n}\n\n@media (prefers-reduced-motion: reduce) {\n  .motion-v2-layer,\n  .motion-v2-scroll,\n  .motion-v2-cursor {\n    display: none !important;\n  }\n\n  .motion-v2-card,\n  .motion-v2-card:hover,\n  .motion-v2-tilt,\n  .motion-v2-tilt:hover,\n  .motion-v2-card:hover > img,\n  .motion-v2-card:hover .script-card__thumb,\n  .motion-v2-card:hover .private-server-card__icon,\n  .motion-v2-card:hover .pinned-game-card__image,\n  .motion-v2-card:hover .bootstrapper-card__logo {\n    transform: none !important;\n    animation: none !important;\n    transition: none !important;\n  }\n\n  .motion-v2-card .motion-v2-sheen,\n  .motion-v2-card .motion-v2-sheen::after {\n    display: none !important;\n  }\n}\n";
  document.head.appendChild(style);

  var reduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var finePointer = window.matchMedia && window.matchMedia('(pointer: fine)').matches;
  var root = document.documentElement;

  function all(selector, scope) {
    return Array.prototype.slice.call((scope || document).querySelectorAll(selector));
  }

  function addLayer() {
    if (document.querySelector('.motion-v2-layer') || reduced) return;
    var layer = document.createElement('div');
    layer.className = 'motion-v2-layer';
    layer.setAttribute('aria-hidden', 'true');
    var data = [
      ['9%', '18%', '260px', 'rgba(102, 227, 255, 0.16)', '60px', '8s', '-1.1s', '18px', '12px'],
      ['88%', '28%', '320px', 'rgba(167, 139, 250, 0.14)', '78px', '11s', '-4s', '-22px', '18px'],
      ['42%', '91%', '240px', 'rgba(72, 199, 116, 0.07)', '70px', '13s', '-7s', '16px', '20px']
    ];
    data.forEach(function (item) {
      var orb = document.createElement('span');
      orb.className = 'motion-v2-orb';
      orb.style.setProperty('--orb-x', item[0]);
      orb.style.setProperty('--orb-y', item[1]);
      orb.style.setProperty('--orb-size', item[2]);
      orb.style.setProperty('--orb-color', item[3]);
      orb.style.setProperty('--orb-blur', item[4]);
      orb.style.setProperty('--orb-duration', item[5]);
      orb.style.setProperty('--orb-delay', item[6]);
      orb.style.setProperty('--orb-drift', item[7]);
      orb.style.setProperty('--orb-rise', item[8]);
      layer.appendChild(orb);
    });
    document.body.appendChild(layer);
  }

  function addScrollBar() {
    if (document.querySelector('.motion-v2-scroll')) return;
    var bar = document.createElement('div');
    bar.className = 'motion-v2-scroll';
    bar.setAttribute('aria-hidden', 'true');
    document.body.appendChild(bar);
    var queued = false;
    function update() {
      var max = document.documentElement.scrollHeight - window.innerHeight;
      var ratio = max > 0 ? Math.max(0, Math.min(1, window.scrollY / max)) : 0;
      bar.style.transform = 'scaleX(' + ratio + ')';
      queued = false;
    }
    window.addEventListener('scroll', function () {
      if (queued) return;
      queued = true;
      window.requestAnimationFrame(update);
    }, { passive: true });
    update();
  }

  function addCursor() {
    if (reduced || !finePointer || document.querySelector('.motion-v2-cursor')) return;
    var cursor = document.createElement('div');
    cursor.className = 'motion-v2-cursor';
    cursor.setAttribute('aria-hidden', 'true');
    document.body.appendChild(cursor);
    var x = -100;
    var y = -100;
    var queued = false;
    function paint() {
      root.style.setProperty('--motion-v2-x', x + 'px');
      root.style.setProperty('--motion-v2-y', y + 'px');
      cursor.style.transform = 'translate3d(' + (x - 14) + 'px, ' + (y - 14) + 'px, 0)';
      queued = false;
    }
    document.addEventListener('pointermove', function (event) {
      x = event.clientX;
      y = event.clientY;
      cursor.classList.add('is-visible');
      if (!queued) {
        queued = true;
        window.requestAnimationFrame(paint);
      }
    }, { passive: true });
    document.addEventListener('pointerdown', function () { cursor.classList.add('is-pressing'); });
    document.addEventListener('pointerup', function () { cursor.classList.remove('is-pressing'); });
    document.addEventListener('pointerleave', function () { cursor.classList.remove('is-visible'); });
  }

  function addSheen(target) {
    if (target.querySelector(':scope > .motion-v2-sheen')) return;
    var sheen = document.createElement('span');
    sheen.className = 'motion-v2-sheen';
    sheen.setAttribute('aria-hidden', 'true');
    target.appendChild(sheen);
  }

  function enhanceCards() {
    var selector = [
      '.home-dashboard',
      '.presence-card',
      '.mcp-spotlight',
      '.pinned-games',
      '.pinned-game-card',
      '.private-server-card',
      '.script-card',
      '.bootstrapper-card',
      '.mcp-download',
      '.tl',
      '.hero-strip',
      '.home-social-hub'
    ].join(',');
    all(selector).forEach(function (target) {
      target.classList.add('motion-v2-card');
      addSheen(target);
    });
    all('.home-dashboard, .presence-card, .mcp-spotlight, .pinned-game-card, .private-server-card, .script-card, .bootstrapper-card, .mcp-download').forEach(function (target) {
      target.classList.add('motion-v2-tilt');
    });
  }

  function bindPointerCards() {
    if (reduced || !finePointer) return;
    var cardSelector = '.motion-v2-card';
    document.addEventListener('pointermove', function (event) {
      var target = event.target.closest && event.target.closest(cardSelector);
      if (!target) return;
      var bounds = target.getBoundingClientRect();
      var x = ((event.clientX - bounds.left) / Math.max(bounds.width, 1)) * 100;
      var y = ((event.clientY - bounds.top) / Math.max(bounds.height, 1)) * 100;
      target.style.setProperty('--motion-v2-card-x', x.toFixed(2) + '%');
      target.style.setProperty('--motion-v2-card-y', y.toFixed(2) + '%');
      if (target.classList.contains('motion-v2-tilt')) {
        target.style.setProperty('--motion-v2-rx', (-((y - 50) / 50) * 4.2).toFixed(2) + 'deg');
        target.style.setProperty('--motion-v2-ry', (((x - 50) / 50) * 4.8).toFixed(2) + 'deg');
      }
    }, { passive: true });
    document.addEventListener('pointerout', function (event) {
      var target = event.target.closest && event.target.closest(cardSelector);
      if (!target || (event.relatedTarget && target.contains(event.relatedTarget))) return;
      target.style.setProperty('--motion-v2-rx', '0deg');
      target.style.setProperty('--motion-v2-ry', '0deg');
    }, { passive: true });
  }

  function bindRipples() {
    if (reduced) return;
    document.addEventListener('pointerdown', function (event) {
      var button = event.target.closest && event.target.closest('button, .btn, .script-card__button, .mcp-download');
      if (!button || button.disabled) return;
      var bounds = button.getBoundingClientRect();
      var ripple = document.createElement('span');
      ripple.className = 'motion-v2-ripple';
      ripple.style.left = (event.clientX - bounds.left) + 'px';
      ripple.style.top = (event.clientY - bounds.top) + 'px';
      button.appendChild(ripple);
      ripple.addEventListener('animationend', function () { ripple.remove(); });
    });
  }

  function burstAt(element) {
    if (reduced) return;
    var bounds = element.getBoundingClientRect();
    var burst = document.createElement('span');
    burst.className = 'motion-v2-nav-burst';
    burst.style.left = (bounds.left + bounds.width / 2) + 'px';
    burst.style.top = (bounds.top + bounds.height / 2) + 'px';
    document.body.appendChild(burst);
    burst.addEventListener('animationend', function () { burst.remove(); });
  }

  function bindNavigation() {
    document.addEventListener('click', function (event) {
      var tab = event.target.closest && event.target.closest('.tb');
      if (!tab) return;
      burstAt(tab);
      var shell = document.querySelector('.pp.on');
      if (shell) {
        window.setTimeout(function () {
          shell.classList.remove('motion-v2-page-surge');
          void shell.offsetWidth;
          shell.classList.add('motion-v2-page-surge');
          window.setTimeout(function () { shell.classList.remove('motion-v2-page-surge'); }, 700);
        }, 20);
      }
    });
  }

  function bindLiveUpdates() {
    var rootNode = document.querySelector('#l');
    if (!rootNode || !window.MutationObserver) return;
    var queued = false;
    var observer = new MutationObserver(function (records) {
      var added = records.some(function (record) {
        return record.type === 'childList' && record.addedNodes.length > 0;
      });
      if (!added || queued) return;
      queued = true;
      window.requestAnimationFrame(function () {
        queued = false;
        enhanceCards();
      });
    });
    observer.observe(rootNode, { subtree: true, childList: true });
  }

  function bindLiveLog() {
    var liveNodes = all('[data-live], .presence-card, .mcp-spotlight');
    if (!window.MutationObserver) return;
    liveNodes.forEach(function (node) {
      new MutationObserver(function () {
        if (reduced) return;
        node.classList.remove('motion-v2-live');
        void node.offsetWidth;
        node.classList.add('motion-v2-live');
      }).observe(node, { childList: true, subtree: true, characterData: true });
    });
  }

  function init() {
    root.classList.add('motion-v2-ready');
    addLayer();
    addScrollBar();
    addCursor();
    enhanceCards();
    bindPointerCards();
    bindRipples();
    bindNavigation();
    bindLiveUpdates();
    bindLiveLog();
  }

  init();
})();