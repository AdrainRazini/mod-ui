// public/js/firebase.js
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.5.0/firebase-app.js";
import { getAuth, GoogleAuthProvider } from "https://www.gstatic.com/firebasejs/11.5.0/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/11.5.0/firebase-firestore.js";


const firebaseConfig = {
  apiKey: "AIzaSyBjuMu3dwfMgBczIF44UhcJkCyvkNO1blY",
  authDomain: "mod-ui.firebaseapp.com",
  projectId: "mod-ui",
  storageBucket: "mod-ui.firebasestorage.app",
  messagingSenderId: "143755281016",
  appId: "1:143755281016:web:a3d7b3aa48e590cbe6638d",
  measurementId: "G-683B49ZWY7"
};


const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const provider = new GoogleAuthProvider();

export { app, auth, db, provider };

// Conexão com os Dados 
