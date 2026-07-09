// =============================================================
// Carat One — Admin: Firebase bootstrap
// Uses the Firebase v10 modular Web SDK (loaded via CDN).
// =============================================================
import { initializeApp }
    from 'https://www.gstatic.com/firebasejs/10.12.5/firebase-app.js';
import {
    getAuth, onAuthStateChanged, signInWithEmailAndPassword,
    signOut, setPersistence, browserLocalPersistence, browserSessionPersistence
} from 'https://www.gstatic.com/firebasejs/10.12.5/firebase-auth.js';
import {
    getDatabase, ref, get, set, update, remove,
    onValue, off, push, query, orderByChild, limitToLast, equalTo,
    serverTimestamp
} from 'https://www.gstatic.com/firebasejs/10.12.5/firebase-database.js';

// Client-side Firebase config — this is safe to expose (matches
// lib/firebase_options.dart::web). Security is enforced entirely by
// Realtime Database rules, not by hiding this config.
const firebaseConfig = {
    apiKey: "AIzaSyBbce9ZWxmPkFNiQ5YS8x4XW9OQyDfh0As",
    authDomain: "caratone-1098a.firebaseapp.com",
    databaseURL: "https://caratone-1098a-default-rtdb.firebaseio.com",
    projectId: "caratone-1098a",
    storageBucket: "caratone-1098a.firebasestorage.app",
    messagingSenderId: "373158700266",
    appId: "1:373158700266:web:86016408e4df8718572393",
    measurementId: "G-4F11D0RVGT"
};

export const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getDatabase(app);

export {
    onAuthStateChanged, signInWithEmailAndPassword, signOut,
    setPersistence, browserLocalPersistence, browserSessionPersistence,
    ref, get, set, update, remove,
    onValue, off, push, query, orderByChild, limitToLast, equalTo,
    serverTimestamp
};
