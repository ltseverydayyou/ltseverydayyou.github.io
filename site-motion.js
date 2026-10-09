(function () {
    "use strict";

    if (window.__DUNGEON_UI_V5__) return;
    window.__DUNGEON_UI_V5__ = true;

    const nav = document.getElementById("site-nav");
    const list = document.getElementById("nb");
    const toggle = document.getElementById("nav-toggle");
    const shade = document.getElementById("nav-shade");
    const find = document.getElementById("nav-find");
    const empty = document.getElementById("nav-empty");
    const main = document.getElementById("workspace");
    const title = document.getElementById("workspace-title");
    const group = document.getElementById("workspace-group");
    const mobile = window.matchMedia("(max-width: 1079px)");
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
    if (!nav || !list || !toggle || !shade || !main) return;

    const paths = {
        h: '<path d="m3 10 9-7 9 7M5 9v11h5v-6h4v6h5V9"/>',
        q: '<path d="M8 3v4m8-4v4M7 7h10v6a5 5 0 0 1-10 0ZM12 18v3M4 10h3m10 0h3"/>',
        s: '<path d="M7 3h10l3 3v15H4V3Zm3 5h4M8 12l-3 3 3 3m8-6 3 3-3 3"/>',
        x: '<circle cx="10" cy="10" r="6"/><path d="m15 15 6 6M8 8l-2 2 2 2m4-4 2 2-2 2"/>',
        y: '<circle cx="12" cy="8" r="4"/><path d="M4 21v-3a8 8 0 0 1 16 0v3"/>',
        a: '<path d="M12 3v12m-5-5 5 5 5-5M4 17v4h16v-4"/>',
        v: '<path d="M4 7h16M4 12h16M4 17h16"/><circle cx="8" cy="7" r="2"/><circle cx="16" cy="12" r="2"/><circle cx="10" cy="17" r="2"/>',
        u: '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 8h18m-13 4 3 3-3 3m6 0h3"/>',
        z: '<path d="m13 2-9 12h7l-1 8 10-13h-7Z"/>',
        e: '<rect x="6" y="6" width="12" height="12" rx="2"/><path d="M9 1v5m6-5v5M9 18v5m6-5v5M1 9h5m-5 6h5m12-6h5m-5 6h5"/>',
        r: '<path d="M7 3h10v4M7 3v4H3v14h18V7h-4M12 9v8m-4-4 4 4 4-4"/>',
        b: '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
        i: '<path d="M3 7h15m-4-4 4 4-4 4M21 17H6m4-4-4 4 4 4"/>',
        c: '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 8h18M8 8v13m4-9 2 2-2 2m5 0h1"/>',
        l: '<path d="m7 6-5 6 5 6m10-12 5 6-5 6M14 3l-4 18"/>',
        m: '<path d="M5 3h10l4 4v14H5ZM15 3v5h4M8 12h8m-8 4h6"/>',
        w: '<rect x="2" y="3" width="20" height="18" rx="2"/><path d="M2 8h20m-14 4-3 3 3 3m8-6 3 3-3 3"/>',
        d: '<path d="M8 3H3v18h5M16 3h5v18h-5M8 8h8m-4-4v8m-4 5h8"/>'
    };

    const buttons = Array.from(list.querySelectorAll(".tb"));
    const names = new Map();
    for (const btn of buttons) {
        const id = btn.dataset.t;
        const label = btn.textContent.trim();
        names.set(id, label);
        btn.type = "button";
        btn.setAttribute("aria-controls", "p" + id);
        const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
        svg.setAttribute("viewBox", "0 0 24 24");
        svg.setAttribute("fill", "none");
        svg.setAttribute("stroke", "currentColor");
        svg.setAttribute("stroke-width", "1.6");
        svg.setAttribute("stroke-linecap", "round");
        svg.setAttribute("stroke-linejoin", "round");
        svg.setAttribute("aria-hidden", "true");
        svg.innerHTML = paths[id] || paths.s;
        const text = document.createElement("span");
        text.className = "tb-text";
        text.textContent = label;
        btn.replaceChildren(svg, text);
    }

    let saved = "";
    let opened = false;
    let timer;
    let observer;

    function filter() {
        const query = find.value.trim().toLowerCase();
        let count = 0;
        for (const btn of buttons) {
            const show = (names.get(btn.dataset.t) || "").toLowerCase().includes(query);
            btn.hidden = !show;
            if (show) count++;
        }
        for (const part of list.querySelectorAll(".nav-group")) {
            part.hidden = !Array.from(part.querySelectorAll(".tb")).some(btn => !btn.hidden);
        }
        empty.hidden = count > 0;
        const results = document.getElementById("nav-results");
        if (results) results.textContent = query ? count + " " + (count === 1 ? "section" : "sections") + " found" : "";
        list.scrollTop = 0;
    }

    function menu(open, restore = true) {
        const next = Boolean(open && mobile.matches);
        if (next === opened) return;
        opened = next;
        nav.classList.toggle("nav-open", next);
        toggle.setAttribute("aria-expanded", String(next));
        toggle.setAttribute("aria-label", next ? "Close section menu" : "Open section menu");
        shade.hidden = !next;
        if (next) {
            saved = document.body.style.overflow;
            document.body.style.overflow = "hidden";
            main.inert = true;
            const active = list.querySelector(".tb.act");
            if (active && !active.hidden) {
                const top = active.getBoundingClientRect().top - list.getBoundingClientRect().top + list.scrollTop;
                list.scrollTop = Math.max(0, top - list.clientHeight / 2);
            }
        } else {
            document.body.style.overflow = saved;
            main.inert = false;
            if (find.value) {
                find.value = "";
                filter();
            }
            if (restore) toggle.focus({ preventScroll: true });
        }
    }

    function reveal(panel) {
        if (!panel) return;
        const nodes = panel.querySelectorAll(":scope > .g, :scope > .mcp-spotlight, :scope > .home-social-hub, :scope > .mcp-details, :scope > .dat-editor");
        for (const node of nodes) {
            if (node.dataset.revealed) continue;
            node.dataset.revealed = "1";
            if (!observer || reduce.matches || node.getBoundingClientRect().top < window.innerHeight) continue;
            node.classList.add("reveal-pending");
            observer.observe(node);
        }
    }

    if ("IntersectionObserver" in window) {
        observer = new IntersectionObserver(entries => {
            for (const entry of entries) {
                if (!entry.isIntersecting) continue;
                entry.target.classList.add("reveal-done");
                observer.unobserve(entry.target);
            }
        }, { rootMargin: "0px 0px -12px 0px", threshold: 0.01 });
    }

    function sync(id, animate = true) {
        const panel = document.getElementById("p" + id);
        if (!panel) return;
        document.body.dataset.page = id;
        const btn = buttons.find(item => item.dataset.t === id);
        title.textContent = names.get(id) || (id === "t" ? "Theme settings" : "Home");
        group.textContent = btn?.closest(".nav-group")?.querySelector(".nav-label")?.textContent || "Settings";
        document.title = id === "h" ? "Vyperia's Dungeon" : title.textContent + " · Vyperia's Dungeon";
        for (const item of buttons) {
            if (item === btn) item.setAttribute("aria-current", "page");
            else item.removeAttribute("aria-current");
        }
        if (animate && !reduce.matches) {
            panel.classList.remove("page-enter");
            void panel.offsetWidth;
            panel.classList.add("page-enter");
        }
        const searchFocused = document.activeElement === find;
        if (find.value) {
            find.value = "";
            filter();
        }
        if (opened) {
            menu(false, false);
            main.focus({ preventScroll: true });
        } else if (searchFocused && animate) {
            main.focus({ preventScroll: true });
        }
        if (!mobile.matches && btn && !btn.hidden) {
            const b = btn.getBoundingClientRect();
            const n = list.getBoundingClientRect();
            if (b.top < n.top || b.bottom > n.bottom) {
                list.scrollTop += b.top - n.top - list.clientHeight / 2 + b.height / 2;
            }
        }
        reveal(panel);
    }

    toggle.addEventListener("click", () => menu(!opened));
    shade.addEventListener("click", () => menu(false));
    find.addEventListener("input", filter);
    find.addEventListener("keydown", event => {
        if (event.key === "Escape" && !opened && find.value) {
            event.preventDefault();
            find.value = "";
            filter();
            return;
        }
        if (event.key === "ArrowDown" || event.key === "ArrowUp") {
            const hits = buttons.filter(btn => !btn.hidden);
            const hit = event.key === "ArrowDown" ? hits[0] : hits[hits.length - 1];
            if (hit) {
                event.preventDefault();
                hit.focus({ preventScroll: true });
                hit.scrollIntoView({ block: "nearest", inline: "nearest" });
            }
            return;
        }
        if (event.key !== "Enter") return;
        const hit = buttons.find(btn => !btn.hidden);
        if (hit) {
            event.preventDefault();
            hit.click();
        }
    });
    nav.addEventListener("keydown", event => {
        const current = event.target.closest(".tb");
        if (current && ["ArrowDown", "ArrowUp", "Home", "End"].includes(event.key)) {
            const hits = buttons.filter(btn => !btn.hidden);
            const index = hits.indexOf(current);
            const next = event.key === "Home" ? 0 : event.key === "End" ? hits.length - 1 : (index + (event.key === "ArrowDown" ? 1 : -1) + hits.length) % hits.length;
            event.preventDefault();
            hits[next]?.focus({ preventScroll: true });
            hits[next]?.scrollIntoView({ block: "nearest", inline: "nearest" });
            return;
        }
        if (!opened) return;
        if (event.key === "Escape") {
            event.preventDefault();
            menu(false);
            return;
        }
        if (event.key !== "Tab") return;
        const items = Array.from(nav.querySelectorAll('button:not([disabled]), input, a[href]')).filter(el => el.getClientRects().length);
        const first = items[0];
        const last = items[items.length - 1];
        if (event.shiftKey && document.activeElement === first) {
            event.preventDefault();
            last.focus();
        } else if (!event.shiftKey && document.activeElement === last) {
            event.preventDefault();
            first.focus();
        }
    });
    document.addEventListener("keydown", event => {
        if (event.key.toLowerCase() !== "k" || !(event.ctrlKey || event.metaKey) || event.altKey || event.repeat) return;
        event.preventDefault();
        menu(true, false);
        find.focus({ preventScroll: true });
        find.select();
    });
    mobile.addEventListener("change", () => menu(false, false));
    reduce.addEventListener("change", () => {
        if (!reduce.matches) return;
        for (const node of document.querySelectorAll(".reveal-pending")) {
            node.classList.add("reveal-done");
            observer?.unobserve(node);
        }
    });
    document.getElementById("workspace-theme")?.addEventListener("click", () => {
        document.getElementById("top-theme-btn")?.click();
    });
    window.addEventListener("dungeon:page", event => sync(event.detail.id));
    window.addEventListener("hashchange", () => {
        const id = location.hash.slice(1) || "h";
        if (document.getElementById("p" + id) && typeof window.tab === "function") window.tab(id, { preserveHash: true });
    });

    const themePanel = document.getElementById("pt");
    function themeReadouts() {
        if (!themePanel) return;
        for (const output of themePanel.querySelectorAll("[data-theme-value]")) {
            const input = document.getElementById(output.dataset.themeValue);
            if (!input) continue;
            const unit = output.dataset.unit || "";
            const value = unit === "%" ? Number((Number(input.value) * 100).toFixed(1)) : unit === "×" ? Number(input.value).toFixed(2).replace(/0+$/, "").replace(/\.$/, "") : input.type === "color" ? input.value.toUpperCase() : input.value;
            output.value = value + unit;
            if (input.type === "range") input.setAttribute("aria-valuetext", output.value);
        }
    }
    themePanel?.addEventListener("input", themeReadouts);
    window.addEventListener("dungeon:theme", themeReadouts);
    document.addEventListener("DOMContentLoaded", themeReadouts);
    themeReadouts();

    const aura = document.getElementById("cursor-aura");
    const finePointer = window.matchMedia("(hover: hover) and (pointer: fine)");
    let pointerFrame = 0;
    let pointerX = 0;
    let pointerY = 0;
    function clearPointer() {
        if (pointerFrame) window.cancelAnimationFrame(pointerFrame);
        pointerFrame = 0;
        aura?.classList.remove("aura-active");
    }
    if (aura) {
        document.addEventListener("pointermove", event => {
            if (!finePointer.matches || reduce.matches || event.pointerType === "touch") return;
            pointerX = event.clientX;
            pointerY = event.clientY;
            if (pointerFrame) return;
            pointerFrame = window.requestAnimationFrame(() => {
                aura.style.transform = "translate3d(" + pointerX + "px, " + pointerY + "px, 0) translate(-50%, -50%)";
                aura.classList.add("aura-active");
                pointerFrame = 0;
            });
        }, { passive: true });
        document.documentElement.addEventListener("pointerleave", clearPointer);
        window.addEventListener("blur", clearPointer);
        document.addEventListener("visibilitychange", () => { if (document.hidden) clearPointer(); });
        reduce.addEventListener("change", clearPointer);
        finePointer.addEventListener("change", clearPointer);
    }

    window.VyperiaToast = window.vyperiaNotify = function (heading, message, opts = {}) {
        const el = document.getElementById("ts");
        if (!el) return;
        if (typeof window.toast === "function") clearTimeout(window.toast._id);
        clearTimeout(timer);
        el.textContent = [heading, message].filter(Boolean).join(" · ");
        el.classList.add("sh");
        timer = window.setTimeout(() => el.classList.remove("sh"), Math.max(1000, Number(opts.duration) || 3200));
        return el;
    };

    const current = document.querySelector(".pp.on");
    sync(current?.id?.slice(1) || location.hash.slice(1) || "h", false);
})();

