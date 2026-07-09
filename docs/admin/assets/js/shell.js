// =============================================================
// Carat One — Admin: shell renderer (sidebar + topbar)
// Consistent chrome across every page.
// =============================================================
export const NAV_ITEMS = [
    { key: 'dashboard',   href: 'dashboard.html',   icon: 'fa-gauge-high',       label: 'Dashboard',    group: 'main' },
    { key: 'users',       href: 'users.html',       icon: 'fa-users',            label: 'Users',        group: 'main' },
    { key: 'inquiries',   href: 'inquiries.html',   icon: 'fa-envelope-open-text', label: 'Website Inquiries', group: 'engage' },
    { key: 'support',     href: 'support.html',     icon: 'fa-life-ring',        label: 'In-App Support', group: 'engage' },
    { key: 'analytics',   href: 'analytics.html',   icon: 'fa-chart-line',       label: 'Analytics',    group: 'insights' },
    { key: 'ad-income',   href: 'ad-income.html',   icon: 'fa-sack-dollar',      label: 'Ad Income',    group: 'insights' },
];

const GROUP_LABELS = { main: 'Overview', engage: 'Engagement', insights: 'Insights' };

/**
 * Render the sidebar into the .sidebar element. Call in every
 * page before requireAdmin(); the guard hydrates the footer.
 */
export function renderSidebar(activeKey) {
    const el = document.querySelector('.sidebar');
    if (!el) return;
    const groups = {};
    for (const item of NAV_ITEMS) (groups[item.group] ||= []).push(item);
    const groupOrder = ['main', 'engage', 'insights'];
    const sections = groupOrder.map(g => `
        <div class="side-section">
            <span class="label">${GROUP_LABELS[g]}</span>
            ${groups[g].map(item => `
                <a class="side-link ${item.key === activeKey ? 'active' : ''}"
                   data-nav="${item.key}" href="${item.href}">
                   <i class="fas ${item.icon}"></i> <span>${item.label}</span>
                </a>`).join('')}
        </div>
    `).join('');
    el.innerHTML = `
        <a class="brand" href="dashboard.html">
            <span class="brand-mark"><i class="fas fa-gem"></i></span>
            <span class="brand-text">
                <b>Carat One</b>
                <span>Admin Console</span>
            </span>
        </a>
        ${sections}
        <div class="side-foot">
            <span class="avatar">A</span>
            <div class="who"><b>Loading…</b><span>Administrator</span></div>
            <button class="signout" data-signout title="Sign out">
                <i class="fas fa-arrow-right-from-bracket"></i>
            </button>
        </div>`;
}

/**
 * Render the topbar into the .topbar element. Pass a page title.
 * Optional accent — a single word rendered in the italic serif.
 */
export function renderTopbar({ title = 'Overview', accent = '', search = true, notifications = true } = {}) {
    const el = document.querySelector('.topbar');
    if (!el) return;
    const parts = title.split(/\s+/);
    let heading = title;
    if (accent) {
        heading = `${title} <span class="accent">${accent}</span>`;
    } else if (parts.length > 1) {
        const last = parts.pop();
        heading = `${parts.join(' ')} <span class="accent">${last}</span>`;
    }
    el.innerHTML = `
        <button class="icon-btn mobile-only" data-menu-toggle aria-label="Open menu">
            <i class="fas fa-bars"></i>
        </button>
        <h1>${heading}</h1>
        <div class="spacer"></div>
        ${search ? `
        <label class="top-search" for="top-search-input">
            <i class="fas fa-magnifying-glass"></i>
            <input id="top-search-input" placeholder="Search users, inquiries…" autocomplete="off">
        </label>` : ''}
        ${notifications ? `
        <button class="icon-btn" title="Notifications">
            <i class="fas fa-bell"></i>
            <span class="dot" id="notif-dot" style="display:none"></span>
        </button>` : ''}
    `;
}
