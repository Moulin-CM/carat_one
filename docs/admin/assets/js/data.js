// =============================================================
// Carat One — Admin: shared data access helpers on top of RTDB
// Pages import from here so paths + shapes are consistent.
// =============================================================
import { db, ref, get, onValue, off, update, remove, push, set, serverTimestamp } from './firebase.js';

// ------------------------------------------------------------------
// Paths
// ------------------------------------------------------------------
export const PATHS = {
    users:      'users',
    admins:     'admins',
    inquiries:  'website_inquiries',
    support:    'support_tickets',
    analytics:  'analytics',
    adIncome:   'ad_income',
};

// ------------------------------------------------------------------
// Snapshot helpers
// ------------------------------------------------------------------
export async function readOnce(path) {
    const snap = await get(ref(db, path));
    return snap.exists() ? snap.val() : null;
}

/**
 * Convert an RTDB "map by id" into an array of { id, ...value }.
 */
export function toRows(map) {
    if (!map) return [];
    return Object.entries(map).map(([id, v]) => ({ id, ...(v || {}) }));
}

/** Subscribe to a path with cleanup. Returns unsub. */
export function subscribe(path, cb) {
    const r = ref(db, path);
    const handler = (snap) => cb(snap.exists() ? snap.val() : null);
    onValue(r, handler);
    return () => off(r, 'value', handler);
}

// ------------------------------------------------------------------
// Users
// ------------------------------------------------------------------
export async function fetchUsers() {
    return toRows(await readOnce(PATHS.users));
}
export async function fetchUser(uid) {
    return await readOnce(`${PATHS.users}/${uid}`);
}
export async function updateUser(uid, patch) {
    await update(ref(db, `${PATHS.users}/${uid}`), {
        ...patch, updatedAt: new Date().toISOString(),
    });
}
export async function deleteUserProfile(uid) {
    await remove(ref(db, `${PATHS.users}/${uid}`));
}

// ------------------------------------------------------------------
// Website inquiries
// ------------------------------------------------------------------
export async function fetchInquiries() {
    return toRows(await readOnce(PATHS.inquiries))
        .sort((a, b) => (Number(b.createdAt) || 0) - (Number(a.createdAt) || 0));
}
export function subscribeInquiries(cb) {
    return subscribe(PATHS.inquiries, (map) => {
        cb(toRows(map).sort((a, b) =>
            (Number(b.createdAt) || 0) - (Number(a.createdAt) || 0)));
    });
}
export async function updateInquiry(id, patch) {
    await update(ref(db, `${PATHS.inquiries}/${id}`), patch);
}
export async function deleteInquiry(id) {
    await remove(ref(db, `${PATHS.inquiries}/${id}`));
}

// ------------------------------------------------------------------
// Support tickets (from within the mobile app)
// ------------------------------------------------------------------
export async function fetchSupportTickets() {
    return toRows(await readOnce(PATHS.support))
        .sort((a, b) => (Number(b.createdAt) || 0) - (Number(a.createdAt) || 0));
}
export function subscribeSupport(cb) {
    return subscribe(PATHS.support, (map) => {
        cb(toRows(map).sort((a, b) =>
            (Number(b.createdAt) || 0) - (Number(a.createdAt) || 0)));
    });
}
export async function updateTicket(id, patch) {
    await update(ref(db, `${PATHS.support}/${id}`), patch);
}
export async function addTicketReply(ticketId, adminUid, adminName, message) {
    const r = ref(db, `${PATHS.support}/${ticketId}/replies`);
    const item = push(r);
    await set(item, {
        by: 'admin',
        adminUid,
        adminName,
        message,
        createdAt: Date.now(),
    });
    await update(ref(db, `${PATHS.support}/${ticketId}`), {
        status: 'open',
        lastReplyAt: Date.now(),
        lastReplyBy: 'admin',
    });
}

// ------------------------------------------------------------------
// Analytics events — written by the Flutter app.
// Expected shape at /analytics/{yyyy-mm-dd}/{eventId} :
//   { type: 'install'|'session_start'|'feature'|'crash'|'purchase',
//     uid: '<user or null>', at: <ms>, extras: { ... } }
// ------------------------------------------------------------------
export async function fetchAnalyticsRange(startDate, endDate) {
    // Read the daily bucket for each day in the range in parallel.
    const days = [];
    const cur = new Date(startDate);
    const end = new Date(endDate);
    while (cur <= end) {
        days.push(fmtDay(cur));
        cur.setDate(cur.getDate() + 1);
    }
    const buckets = await Promise.all(
        days.map(d => readOnce(`${PATHS.analytics}/${d}`)));
    return days.map((day, i) => ({ day, events: toRows(buckets[i]) }));
}

export function fmtDay(d) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${dd}`;
}

/** Roll up events into { installs, sessions, activeUsers, crashes } per day. */
export function rollupDaily(rangeBuckets) {
    return rangeBuckets.map(b => {
        const uniqUsers = new Set();
        let installs = 0, sessions = 0, crashes = 0, features = 0;
        for (const e of b.events) {
            if (e.uid) uniqUsers.add(e.uid);
            switch (e.type) {
                case 'install': installs++; break;
                case 'session_start': sessions++; break;
                case 'crash': crashes++; break;
                case 'feature': features++; break;
            }
        }
        return {
            day: b.day,
            installs, sessions, features, crashes,
            activeUsers: uniqUsers.size,
        };
    });
}

// ------------------------------------------------------------------
// Ad income entries stored at /ad_income/{YYYY-MM}
// ------------------------------------------------------------------
export async function fetchAdIncomeAll() {
    const map = await readOnce(PATHS.adIncome);
    return toRows(map).sort((a, b) => a.id.localeCompare(b.id));
}
export async function saveAdIncome(monthId, entry) {
    await set(ref(db, `${PATHS.adIncome}/${monthId}`), {
        ...entry,
        month: monthId,
        updatedAt: Date.now(),
    });
}
export async function deleteAdIncome(monthId) {
    await remove(ref(db, `${PATHS.adIncome}/${monthId}`));
}

export { serverTimestamp };
