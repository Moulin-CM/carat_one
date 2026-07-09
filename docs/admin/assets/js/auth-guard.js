// =============================================================
// Carat One — Admin: Route guard + shared session/topbar helpers
//
// Every protected page imports this module. It:
//   1. Waits for Firebase auth state.
//   2. Verifies the signed-in uid appears under /admins/{uid} in
//      Realtime Database. This is the *client* check — the server
//      side is enforced by database.rules.json.
//   3. If verified, sets window.__adminSession and calls onReady().
//   4. Otherwise redirects to /admin/ (login).
// =============================================================
import {
    auth, db, ref, get, onAuthStateChanged, signOut
} from './firebase.js';
import { toast } from './ui.js';

const LOGIN_PAGE = 'index.html';

/**
 * Guard the current page. Returns a promise that resolves to
 * { user, admin } when the session is verified, or redirects.
 * @param {Object} opts
 * @param {boolean} [opts.redirect=true] — if false, resolves to null instead of redirecting.
 */
export function requireAdmin(opts = {}) {
    const redirect = opts.redirect !== false;
    return new Promise((resolve) => {
        onAuthStateChanged(auth, async (user) => {
            if (!user) {
                if (redirect) window.location.replace(LOGIN_PAGE);
                else resolve(null);
                return;
            }
            try {
                const snap = await get(ref(db, `admins/${user.uid}`));
                if (!snap.exists()) {
                    await signOut(auth);
                    if (redirect) {
                        sessionStorage.setItem('admin:flash',
                            'This account is not authorised to access the admin panel.');
                        window.location.replace(LOGIN_PAGE);
                    } else resolve(null);
                    return;
                }
                const admin = snap.val() || {};
                window.__adminSession = { user, admin };
                paintSidebarFooter(user, admin);
                wireSignOut();
                resolve({ user, admin });
            } catch (err) {
                console.error('[admin] auth check failed', err);
                toast('Could not verify admin access.', 'err');
                if (redirect) window.location.replace(LOGIN_PAGE);
                else resolve(null);
            }
        });
    });
}

function paintSidebarFooter(user, admin) {
    const foot = document.querySelector('.side-foot');
    if (!foot) return;
    const name = admin.name || user.displayName || user.email.split('@')[0];
    const initials = name.split(/\s+/).map(p => p[0]).slice(0, 2).join('').toUpperCase() || 'A';
    const avatar = foot.querySelector('.avatar');
    const nameEl = foot.querySelector('.who b');
    const roleEl = foot.querySelector('.who span');
    if (avatar) avatar.textContent = initials;
    if (nameEl) nameEl.textContent = name;
    if (roleEl) roleEl.textContent = admin.role || 'Administrator';
}

function wireSignOut() {
    const btn = document.querySelector('[data-signout]');
    if (!btn) return;
    btn.addEventListener('click', async () => {
        try {
            await signOut(auth);
            window.location.replace(LOGIN_PAGE);
        } catch (e) {
            toast('Sign out failed.', 'err');
        }
    });
}

/**
 * Highlight the active nav link. Pages call this in their init.
 * @param {string} key — the data-nav attribute value to activate
 */
export function markActive(key) {
    document.querySelectorAll('.side-link').forEach(a => {
        a.classList.toggle('active', a.dataset.nav === key);
    });
}
