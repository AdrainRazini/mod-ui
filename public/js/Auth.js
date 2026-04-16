// public/js/firebase.js
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.5.0/firebase-app.js";
import { getAuth, GoogleAuthProvider } from "https://www.gstatic.com/firebasejs/11.5.0/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/11.5.0/firebase-firestore.js";


const firebaseConfig = {
  apiKey: "AIzaSyA0xGJY3hZu56GRxn9wAy6CImbYqcO-Zds",
  authDomain: "pontos-sdk.firebaseapp.com",
  projectId: "pontos-sdk",
  storageBucket: "pontos-sdk.firebasestorage.app",
  messagingSenderId: "374726213745",
  appId: "1:374726213745:web:bc4207fee40acab9b3dbd0",
  measurementId: "G-VDZWL568KF"
};


const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const provider = new GoogleAuthProvider();

export { app, auth, db, provider };

// Conexão com os Dados 