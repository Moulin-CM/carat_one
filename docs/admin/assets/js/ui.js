// =============================================================
// Carat One — Admin: shared UI utilities
// Cursor, aurora background, reveal-on-scroll, toasts, modals,
// small formatters. Everything here has no dependencies beyond
// the DOM so pages can import it early.
// =============================================================

// ---------------------------- Cursor ----------------------------
export function initCursor() {
    if (!matchMedia('(hover:hover) and (pointer:fine)').matches) return;
    const dot = document.createElement('div');
    const ring = document.createElement('div');
    dot.className = 'cursor-dot';
    ring.className = 'cursor-ring';
    document.body.appendChild(dot);
    document.body.appendChild(ring);
    let x = window.innerWidth / 2, y = window.innerHeight / 2;
    let rx = x, ry = y;
    document.addEventListener('mousemove', (e) => { x = e.clientX; y = e.clientY; });
    const loop = () => {
        rx += (x - rx) * 0.18;
        ry += (y - ry) * 0.18;
        dot.style.transform  = `translate(${x}px, ${y}px)`;
        ring.style.transform = `translate(${rx}px, ${ry}px)`;
        requestAnimationFrame(loop);
    };
    loop();
    const hoverSel = 'a,button,input,select,textarea,.kpi-card,.side-link,.icon-btn,.row-action,.btn';
    document.addEventListener('mouseover', (e) => {
        if (e.target.closest(hoverSel)) {
            ring.classList.add('is-hover');
            dot.classList.add('is-hover');
        }
    });
    document.addEventListener('mouseout', (e) => {
        if (e.target.closest(hoverSel)) {
            ring.classList.remove('is-hover');
            dot.classList.remove('is-hover');
        }
    });
}

// ---------------------------- Aurora ----------------------------
export function mountAurora() {
    if (document.querySelector('.aurora')) return;
    const wrap = document.createElement('div');
    wrap.className = 'aurora';
    wrap.innerHTML = `
        <span class="blob blob-a"></span>
        <span class="blob blob-b"></span>
        <span class="blob blob-c"></span>`;
    document.body.prepend(wrap);
    const grid = document.createElement('div');
    grid.className = 'grid-overlay';
    document.body.prepend(grid);
}

// -------------------------- Reveal on scroll --------------------
export function initReveal() {
    const items = document.querySelectorAll('.reveal');
    if (!('IntersectionObserver' in window)) {
        items.forEach(el => el.classList.add('is-in'));
        return;
    }
    const io = new IntersectionObserver((entries) => {
        entries.forEach((e) => {
            if (e.isIntersecting) {
                e.target.classList.add('is-in');
                io.unobserve(e.target);
            }
        });
    }, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });
    items.forEach(el => io.observe(el));
}

// -------------------------- Card tilt spotlight -----------------
export function initCardSpotlight() {
    document.addEventListener('mousemove', (e) => {
        const card = e.target.closest('.card, .kpi-card');
        if (!card) return;
        const r = card.getBoundingClientRect();
        card.style.setProperty('--mx', `${((e.clientX - r.left) / r.width) * 100}%`);
        card.style.setProperty('--my', `${((e.clientY - r.top) / r.height) * 100}%`);
    });
}

// -------------------------- Toasts ------------------------------
let toastStack;
export function toast(message, kind = 'info', ms = 3600) {
    if (!toastStack) {
        toastStack = document.createElement('div');
        toastStack.className = 'toast-stack';
        document.body.appendChild(toastStack);
    }
    const icons = { ok: 'fa-check', err: 'fa-triangle-exclamation', info: 'fa-circle-info' };
    const el = document.createElement('div');
    el.className = `toast ${kind}`;
    el.innerHTML = `
        <span class="icon"><i class="fas ${icons[kind] || icons.info}"></i></span>
        <span class="msg"></span>
        <button class="close" aria-label="close"><i class="fas fa-xmark"></i></button>`;
    el.querySelector('.msg').textContent = message;
    el.querySelector('.close').onclick = () => dismiss();
    toastStack.appendChild(el);
    const dismiss = () => {
        el.style.transition = 'opacity .25s, transform .25s';
        el.style.opacity = '0';
        el.style.transform = 'translateY(8px)';
        setTimeout(() => el.remove(), 260);
    };
    setTimeout(dismiss, ms);
}

// -------------------------- Modals ------------------------------
export function openModal(id) {
    const el = document.getElementById(id);
    if (!el) return;
    el.classList.add('is-open');
    document.body.style.overflow = 'hidden';
}
export function closeModal(id) {
    const el = document.getElementById(id);
    if (!el) return;
    el.classList.remove('is-open');
    document.body.style.overflow = '';
}
export function wireModal(id) {
    const el = document.getElementById(id);
    if (!el) return;
    el.addEventListener('click', (e) => {
        if (e.target === el || e.target.dataset.close === '') closeModal(id);
    });
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && el.classList.contains('is-open')) closeModal(id);
    });
}

// -------------------------- Mobile sidebar ----------------------
export function initMobileNav() {
    const btn = document.querySelector('[data-menu-toggle]');
    const side = document.querySelector('.sidebar');
    if (!btn || !side) return;
    btn.addEventListener('click', () => side.classList.toggle('is-open'));
    document.addEventListener('click', (e) => {
        if (!side.classList.contains('is-open')) return;
        if (e.target.closest('.sidebar') || e.target.closest('[data-menu-toggle]')) return;
        side.classList.remove('is-open');
    });
}

// -------------------------- Formatters --------------------------
export function fmtNum(n) {
    if (n === null || n === undefined || isNaN(n)) return '0';
    return new Intl.NumberFormat('en-IN').format(Math.round(n));
}
export function fmtInr(n) {
    if (n === null || n === undefined || isNaN(n)) return '₹0';
    return '₹' + new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 }).format(n);
}
export function fmtDate(ts) {
    if (!ts) return '—';
    const d = ts instanceof Date ? ts : new Date(typeof ts === 'string' ? ts : Number(ts));
    if (isNaN(d)) return '—';
    return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
}
export function fmtDateTime(ts) {
    if (!ts) return '—';
    const d = ts instanceof Date ? ts : new Date(typeof ts === 'string' ? ts : Number(ts));
    if (isNaN(d)) return '—';
    return d.toLocaleString('en-IN',
        { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}
export function relTime(ts) {
    if (!ts) return '—';
    const d = ts instanceof Date ? ts : new Date(typeof ts === 'string' ? ts : Number(ts));
    if (isNaN(d)) return '—';
    const diff = (Date.now() - d.getTime()) / 1000;
    if (diff < 60) return 'just now';
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    if (diff < 86400 * 7) return `${Math.floor(diff / 86400)}d ago`;
    return fmtDate(d);
}
export function initials(name = '', fallback = '?') {
    const s = (name || '').trim();
    if (!s) return fallback;
    return s.split(/\s+/).map(p => p[0]).slice(0, 2).join('').toUpperCase();
}
export function pickAvatarClass(seed = '') {
    const opts = ['', 'v-violet', 'v-green', 'v-gold', 'v-rose'];
    let h = 0;
    for (let i = 0; i < seed.length; i++) h = (h * 31 + seed.charCodeAt(i)) >>> 0;
    return opts[h % opts.length];
}

// -------------------------- One-liner boot ----------------------
export function bootChrome() {
    mountAurora();
    initCursor();
    initReveal();
    initCardSpotlight();
    initMobileNav();
}
