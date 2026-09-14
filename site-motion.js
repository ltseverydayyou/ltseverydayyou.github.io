(function () {
  "use strict";

  if (window.__VYPERIA_MOTION_V3__) return;
  window.__VYPERIA_MOTION_V3__ = true;

  var reduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var finePointer = window.matchMedia && window.matchMedia('(pointer: fine)').matches;

  var style = document.createElement('style');
  style.id = 'vyperia-motion-v3';
  style.textContent = `
:root {
  --mcp-purple: #8b5cf6;
  --mcp-purple-bright: #a78bfa;
  --mcp-purple-soft: rgba(139, 92, 246, .16);
  --mcp-purple-faint: rgba(139, 92, 246, .08);
  --mcp-surface: rgba(15, 12, 28, .72);
  --mcp-surface-raised: rgba(23, 18, 40, .86);
  --mcp-border: rgba(167, 139, 250, .16);
  --mcp-border-hover: rgba(167, 139, 250, .34);
  --mcp-shadow: 0 18px 60px rgba(0, 0, 0, .34);
  --mcp-ease: cubic-bezier(.16, 1, .3, 1);
  --mcp-fast: 150ms;
  --mcp-med: 260ms;
}

html { scroll-behavior: smooth; }
body { background-color: #090611; }
body.mcp-motion-ready { --ambientA: .5; }

.mcp-ambient {
  position: fixed;
  inset: 0;
  z-index: 0;
  overflow: hidden;
  pointer-events: none;
  contain: strict;
}
.mcp-ambient::before {
  content: "";
  position: absolute;
  inset: -18%;
  background:
    radial-gradient(38% 34% at var(--mcp-pointer-x, 58%) var(--mcp-pointer-y, 20%), rgba(139, 92, 246, .18), transparent 72%),
    radial-gradient(34% 42% at 86% 76%, rgba(88, 28, 135, .17), transparent 72%),
    radial-gradient(26% 34% at 8% 82%, rgba(99, 58, 180, .12), transparent 72%);
  filter: blur(26px) saturate(118%);
  animation: mcpAmbient 16s ease-in-out infinite alternate;
}
.mcp-ambient::after {
  content: "";
  position: absolute;
  inset: 0;
  opacity: .13;
  background-image: linear-gradient(rgba(167,139,250,.028) 1px, transparent 1px), linear-gradient(90deg, rgba(167,139,250,.028) 1px, transparent 1px);
  background-size: 38px 38px;
  mask-image: linear-gradient(to bottom, rgba(0,0,0,.75), transparent 76%);
}

.mcp-surface {
  position: relative;
  isolation: isolate;
  border-color: var(--mcp-border) !important;
  transition: transform var(--mcp-med) var(--mcp-ease), border-color var(--mcp-fast) ease, box-shadow var(--mcp-med) var(--mcp-ease), background var(--mcp-med) ease, filter var(--mcp-med) ease !important;
}
.mcp-surface::before {
  content: "";
  position: absolute;
  inset: 0;
  z-index: 0;
  pointer-events: none;
  border-radius: inherit;
  opacity: 0;
  background: radial-gradient(circle at var(--mcp-card-x, 50%) var(--mcp-card-y, 50%), rgba(167,139,250,.14), transparent 34%);
  transition: opacity var(--mcp-med) ease;
}
.mcp-surface > * { position: relative; z-index: 1; }
.mcp-surface:hover {
  transform: translateY(-3px);
  border-color: var(--mcp-border-hover) !important;
  box-shadow: var(--mcp-shadow), 0 0 0 1px rgba(139,92,246,.05), 0 0 38px rgba(99,58,180,.08) !important;
  filter: saturate(1.04);
}
.mcp-surface:hover::before { opacity: 1; }

button, .btn, [role="button"], a, input, select, textarea {
  transition-timing-function: var(--mcp-ease) !important;
}
button, .btn, [role="button"] { transform: translateZ(0); }
button:hover, .btn:hover, [role="button"]:hover { filter: brightness(1.06); }
button:active, .btn:active, [role="button"]:active { transform: scale(.975); }
button:focus-visible, .btn:focus-visible, [role="button"]:focus-visible, a:focus-visible, input:focus-visible, select:focus-visible, textarea:focus-visible {
  outline: 2px solid var(--mcp-purple-bright) !important;
  outline-offset: 2px !important;
}

.mcp-ripple {
  position: absolute;
  width: 12px;
  height: 12px;
  border-radius: 999px;
  pointer-events: none;
  background: rgba(196, 181, 253, .42);
  transform: translate(-50%, -50%) scale(0);
  animation: mcpRipple 620ms ease-out forwards;
  z-index: 20;
}

.mcp-scroll-progress {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 2px;
  z-index: 10020;
  pointer-events: none;
  transform: scaleX(0);
  transform-origin: left center;
  background: linear-gradient(90deg, #6d28d9, #8b5cf6 45%, #c4b5fd);
  box-shadow: 0 0 16px rgba(139,92,246,.5);
}

.mcp-toast-stack {
  position: fixed;
  right: 18px;
  bottom: 18px;
  z-index: 11000;
  display: flex;
  flex-direction: column;
  gap: 10px;
  width: min(380px, calc(100vw - 28px));
  pointer-events: none;
}
.mcp-toast {
  pointer-events: auto;
  display: grid;
  grid-template-columns: 34px 1fr auto;
  gap: 10px;
  align-items: start;
  padding: 12px 12px 12px 11px;
  border: 1px solid rgba(167,139,250,.2);
  border-radius: 10px;
  background: rgba(14, 10, 26, .94);
  color: #f3efff;
  box-shadow: 0 18px 50px rgba(0,0,0,.38), 0 0 0 1px rgba(139,92,246,.04) inset;
  backdrop-filter: blur(14px);
  animation: mcpToastIn 360ms var(--mcp-ease) both;
  overflow: hidden;
}
.mcp-toast.is-leaving { animation: mcpToastOut 240ms ease forwards; }
.mcp-toast-icon {
  width: 34px;
  height: 34px;
  display: grid;
  place-items: center;
  border-radius: 8px;
  color: #ddd2ff;
  background: rgba(139,92,246,.14);
  border: 1px solid rgba(167,139,250,.18);
  font-weight: 800;
}
.mcp-toast-title { font: 700 13px/1.3 inherit; margin: 1px 0 3px; }
.mcp-toast-message { color: rgba(226,220,242,.72); font-size: 12px; line-height: 1.45; }
.mcp-toast-close {
  appearance: none;
  border: 0;
  background: transparent;
  color: rgba(226,220,242,.55);
  cursor: pointer;
  font-size: 18px;
  line-height: 1;
  padding: 2px 3px;
}
.mcp-toast::after {
  content: "";
  position: absolute;
  left: 0;
  bottom: 0;
  height: 2px;
  width: 100%;
  transform-origin: left center;
  background: linear-gradient(90deg, #7c3aed, #a78bfa);
  animation: mcpToastTimer var(--mcp-toast-duration, 3200ms) linear forwards;
}

.mcp-modal-enter { animation: mcpModalIn 300ms var(--mcp-ease) both !important; }
.mcp-dropdown-enter { animation: mcpDropIn 220ms var(--mcp-ease) both !important; transform-origin: top center; }

.mcp-cursor {
  position: fixed;
  left: 0;
  top: 0;
  z-index: 10030;
  width: 24px;
  height: 24px;
  pointer-events: none;
  border: 1px solid rgba(196,181,253,.58);
  border-radius: 50%;
  opacity: 0;
  transform: translate3d(-100px,-100px,0);
  transition: width 160ms var(--mcp-ease), height 160ms var(--mcp-ease), opacity 160ms ease, border-color 160ms ease;
  mix-blend-mode: screen;
}
.mcp-cursor::after {
  content: "";
  position: absolute;
  width: 4px;
  height: 4px;
  left: 50%;
  top: 50%;
  border-radius: 50%;
  transform: translate(-50%,-50%);
  background: #fff;
  box-shadow: 0 0 14px rgba(167,139,250,.9);
}
.mcp-cursor.is-visible { opacity: .72; }
.mcp-cursor.is-active { width: 36px; height: 36px; border-color: #fff; }

@keyframes mcpAmbient { from { transform: scale(1) translate3d(-1%,-1%,0); } to { transform: scale(1.07) translate3d(1%,1.5%,0); } }
@keyframes mcpRipple { to { opacity: 0; transform: translate(-50%,-50%) scale(28); } }
@keyframes mcpToastIn { from { opacity: 0; transform: translate3d(18px, 8px, 0) scale(.98); } to { opacity: 1; transform: none; } }
@keyframes mcpToastOut { to { opacity: 0; transform: translate3d(16px, 0, 0) scale(.98); } }
@keyframes mcpToastTimer { from { transform: scaleX(1); } to { transform: scaleX(0); } }
@keyframes mcpModalIn { from { opacity: 0; transform: translateY(8px) scale(.985); } to { opacity: 1; transform: none; } }
@keyframes mcpDropIn { from { opacity: 0; transform: translateY(-5px) scaleY(.97); } to { opacity: 1; transform: none; } }

@media (max-width: 760px) {
  .mcp-toast-stack { right: 12px; bottom: 12px; width: calc(100vw - 24px); }
  .mcp-surface:hover { transform: translateY(-2px); }
  .mcp-cursor { display: none !important; }
}

@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  .mcp-ambient, .mcp-scroll-progress, .mcp-cursor { display: none !important; }
  .mcp-surface, .mcp-surface:hover, button, .btn, [role="button"], .mcp-toast, .mcp-modal-enter, .mcp-dropdown-enter {
    animation: none !important;
    transition-duration: 0ms !important;
    transform: none !important;
  }
}
`;
  document.head.appendChild(style);

  function all(selector, scope) {
    return Array.prototype.slice.call((scope || document).querySelectorAll(selector));
  }

  function addAmbient() {
    if (reduced || document.querySelector('.mcp-ambient')) return;
    var layer = document.createElement('div');
    layer.className = 'mcp-ambient';
    layer.setAttribute('aria-hidden', 'true');
    document.body.prepend(layer);
  }

  function addProgress() {
    if (reduced || document.querySelector('.mcp-scroll-progress')) return;
    var bar = document.createElement('div');
    bar.className = 'mcp-scroll-progress';
    bar.setAttribute('aria-hidden', 'true');
    document.body.appendChild(bar);
    function update() {
      var max = Math.max(1, document.documentElement.scrollHeight - window.innerHeight);
      bar.style.transform = 'scaleX(' + Math.max(0, Math.min(1, window.scrollY / max)) + ')';
    }
    update();
    window.addEventListener('scroll', update, { passive: true });
    window.addEventListener('resize', update, { passive: true });
  }

  function toast(title, message, options) {
    options = options || {};
    var duration = Number(options.duration || 3200);
    var stack = document.querySelector('.mcp-toast-stack');
    if (!stack) {
      stack = document.createElement('div');
      stack.className = 'mcp-toast-stack';
      stack.setAttribute('aria-live', 'polite');
      document.body.appendChild(stack);
    }
    var item = document.createElement('div');
    item.className = 'mcp-toast';
    item.style.setProperty('--mcp-toast-duration', duration + 'ms');
    var icon = options.icon || (options.type === 'error' ? '!' : options.type === 'success' ? '✓' : 'i');
    item.innerHTML = '<div class="mcp-toast-icon"></div><div><div class="mcp-toast-title"></div><div class="mcp-toast-message"></div></div><button class="mcp-toast-close" type="button" aria-label="Dismiss">×</button>';
    item.querySelector('.mcp-toast-icon').textContent = icon;
    item.querySelector('.mcp-toast-title').textContent = title || 'Notice';
    item.querySelector('.mcp-toast-message').textContent = message || '';
    stack.appendChild(item);
    var dead = false;
    function dismiss() {
      if (dead) return;
      dead = true;
      item.classList.add('is-leaving');
      window.setTimeout(function () { item.remove(); }, reduced ? 0 : 250);
    }
    item.querySelector('.mcp-toast-close').addEventListener('click', dismiss);
    window.setTimeout(dismiss, duration);
    return item;
  }

  window.VyperiaToast = toast;
  window.vyperiaNotify = toast;

  var surfaceSelector = [
    '.card', '.panel', '.script-card', '.private-server-card', '.pinned-game-card', '.bootstrapper-card',
    '.repo-card', '.tool-card', '.glass', '.modal-content', '.dialog', '.notice', '.status-card',
    '.executor-card', '.feature-card', '.update-card', '.server-card', '.home-dashboard', '.presence-card',
    '.mcp-spotlight', '.pinned-games', '.mcp-download', '.tl', '.hero-strip', '.home-social-hub'
  ].join(',');

  function decorate(root) {
    all(surfaceSelector, root).forEach(function (el) {
      if (el.classList.contains('mcp-surface')) return;
      el.classList.add('mcp-surface');
      if (!reduced && finePointer) {
        el.addEventListener('pointermove', function (ev) {
          var r = el.getBoundingClientRect();
          el.style.setProperty('--mcp-card-x', ((ev.clientX - r.left) / Math.max(1, r.width) * 100).toFixed(1) + '%');
          el.style.setProperty('--mcp-card-y', ((ev.clientY - r.top) / Math.max(1, r.height) * 100).toFixed(1) + '%');
        });
      }
    });
  }

  function addRipple(ev) {
    var target = ev.target.closest('button, .btn, [role="button"], .tb, .hero__actions > *, .as-actions > *');
    if (!target || reduced) return;
    var css = window.getComputedStyle(target);
    if (css.position === 'static') target.style.position = 'relative';
    if (css.overflow === 'visible') target.style.overflow = 'hidden';
    var r = target.getBoundingClientRect();
    var dot = document.createElement('span');
    dot.className = 'mcp-ripple';
    dot.style.left = (ev.clientX - r.left) + 'px';
    dot.style.top = (ev.clientY - r.top) + 'px';
    target.appendChild(dot);
    window.setTimeout(function () { dot.remove(); }, 700);
  }

  function animateNewNode(node) {
    if (!(node instanceof Element)) return;
    decorate(node);
    var cls = (node.className || '').toString().toLowerCase();
    var role = (node.getAttribute('role') || '').toLowerCase();
    if (/modal|dialog|overlay|popup/.test(cls) || role === 'dialog') node.classList.add('mcp-modal-enter');
    if (/dropdown|menu|popover|context/.test(cls) || role === 'menu') node.classList.add('mcp-dropdown-enter');
  }

  function setupMutationObserver() {
    var observer = new MutationObserver(function (records) {
      records.forEach(function (record) {
        Array.prototype.forEach.call(record.addedNodes, animateNewNode);
      });
    });
    observer.observe(document.body, { childList: true, subtree: true });
  }

  function setupCursor() {
    if (reduced || !finePointer || document.querySelector('.mcp-cursor')) return;
    var cursor = document.createElement('div');
    cursor.className = 'mcp-cursor';
    cursor.setAttribute('aria-hidden', 'true');
    document.body.appendChild(cursor);
    var x = -100, y = -100, tx = -100, ty = -100;
    function tick() {
      x += (tx - x) * .24;
      y += (ty - y) * .24;
      cursor.style.transform = 'translate3d(' + (x - 12) + 'px,' + (y - 12) + 'px,0)';
      requestAnimationFrame(tick);
    }
    document.addEventListener('pointermove', function (ev) {
      tx = ev.clientX; ty = ev.clientY;
      cursor.classList.add('is-visible');
      document.documentElement.style.setProperty('--mcp-pointer-x', (ev.clientX / Math.max(1, innerWidth) * 100).toFixed(1) + '%');
      document.documentElement.style.setProperty('--mcp-pointer-y', (ev.clientY / Math.max(1, innerHeight) * 100).toFixed(1) + '%');
    }, { passive: true });
    document.addEventListener('pointerdown', function () { cursor.classList.add('is-active'); }, { passive: true });
    document.addEventListener('pointerup', function () { cursor.classList.remove('is-active'); }, { passive: true });
    document.addEventListener('mouseleave', function () { cursor.classList.remove('is-visible'); }, { passive: true });
    requestAnimationFrame(tick);
  }

  function setupCopyFeedback() {
    document.addEventListener('click', function (ev) {
      var el = ev.target.closest('[data-copy], .copy-btn, .copy-button, button');
      if (!el) return;
      var text = (el.textContent || '').trim().toLowerCase();
      var title = (el.getAttribute('title') || '').toLowerCase();
      if (!/copy/.test(text + ' ' + title) && !el.hasAttribute('data-copy')) return;
      window.setTimeout(function () { toast('Copied', 'Copied to clipboard.', { type: 'success', duration: 1800 }); }, 30);
    }, true);
  }

  function init() {
    addAmbient();
    addProgress();
    decorate(document);
    setupMutationObserver();
    setupCursor();
    setupCopyFeedback();
    document.addEventListener('pointerdown', addRipple, true);
    document.body.classList.add('mcp-motion-ready');
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init, { once: true });
  else init();
})();
