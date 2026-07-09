/**
 * Carat One — Admin Cloud Functions
 *
 * These callable functions expose Firebase Auth Admin SDK operations
 * (list, disable, delete) that the browser-side admin panel cannot
 * perform on its own. Requires the Blaze plan.
 *
 * Deploy:
 *   cd docs/admin/functions
 *   npm install
 *   firebase deploy --only functions
 *
 * All callables verify the caller against `/admins/{uid}` in RTDB
 * before doing anything privileged.
 */
const functions = require('firebase-functions/v2');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.database();
const auth = admin.auth();

/** Throw if the caller is not present in /admins/{uid}. */
async function assertAdmin(request) {
    if (!request.auth || !request.auth.uid) {
        throw new HttpsError('unauthenticated', 'You must be signed in.');
    }
    const snap = await db.ref(`admins/${request.auth.uid}`).get();
    if (!snap.exists()) {
        throw new HttpsError('permission-denied', 'Admin access required.');
    }
    return snap.val();
}

/**
 * listAuthUsers({ pageToken? }) → { users: [...], nextPageToken }
 *
 * Returns Firebase Auth users — the profile info the client SDK
 * cannot query (last sign-in, disabled state, verified email…).
 */
exports.listAuthUsers = onCall(
    {region: 'asia-south1', cors: true},
    async (request) => {
        await assertAdmin(request);
        const {pageToken} = request.data || {};
        const result = await auth.listUsers(1000, pageToken);
        return {
            users: result.users.map((u) => ({
                uid: u.uid,
                email: u.email,
                emailVerified: u.emailVerified,
                displayName: u.displayName,
                phoneNumber: u.phoneNumber,
                disabled: u.disabled,
                metadata: {
                    creationTime: u.metadata.creationTime,
                    lastSignInTime: u.metadata.lastSignInTime,
                    lastRefreshTime: u.metadata.lastRefreshTime,
                },
                providers: (u.providerData || []).map((p) => p.providerId),
            })),
            nextPageToken: result.pageToken || null,
        };
    },
);

/** disableAuthUser({ uid, disabled }) */
exports.disableAuthUser = onCall(
    {region: 'asia-south1', cors: true},
    async (request) => {
        await assertAdmin(request);
        const {uid, disabled} = request.data || {};
        if (!uid) throw new HttpsError('invalid-argument', 'uid is required');
        await auth.updateUser(uid, {disabled: Boolean(disabled)});
        return {uid, disabled: Boolean(disabled)};
    },
);

/** deleteAuthUser({ uid }) — also removes the profile at /users/{uid}. */
exports.deleteAuthUser = onCall(
    {region: 'asia-south1', cors: true},
    async (request) => {
        await assertAdmin(request);
        const {uid} = request.data || {};
        if (!uid) throw new HttpsError('invalid-argument', 'uid is required');
        await auth.deleteUser(uid);
        await db.ref(`users/${uid}`).remove().catch(() => {});
        return {uid, deleted: true};
    },
);

/**
 * dailySnapshot() — scheduled aggregator that rolls up the previous
 * day's /analytics/{yyyy-MM-dd}/* into /analytics_daily/{yyyy-MM-dd}
 * so the admin panel doesn't pay the read cost of every event.
 * Uncomment to enable — requires the Blaze plan.
 */
// exports.dailySnapshot = functions.scheduler.onSchedule(
//     {schedule: 'every day 01:15', timeZone: 'Asia/Kolkata', region: 'asia-south1'},
//     async () => {
//         const y = new Date(Date.now() - 24 * 3600 * 1000);
//         const day = `${y.getFullYear()}-${String(y.getMonth() + 1).padStart(2, '0')}-${String(y.getDate()).padStart(2, '0')}`;
//         const snap = await db.ref(`analytics/${day}`).get();
//         if (!snap.exists()) return;
//         const roll = {installs: 0, sessions: 0, features: 0, crashes: 0, uniqUsers: {}};
//         snap.forEach((child) => {
//             const v = child.val() || {};
//             if (v.uid) roll.uniqUsers[v.uid] = true;
//             switch (v.type) {
//                 case 'install':       roll.installs++; break;
//                 case 'session_start': roll.sessions++; break;
//                 case 'feature':       roll.features++; break;
//                 case 'crash':         roll.crashes++;  break;
//             }
//         });
//         await db.ref(`analytics_daily/${day}`).set({
//             day,
//             installs: roll.installs,
//             sessions: roll.sessions,
//             features: roll.features,
//             crashes: roll.crashes,
//             activeUsers: Object.keys(roll.uniqUsers).length,
//             at: Date.now(),
//         });
//     },
// );
