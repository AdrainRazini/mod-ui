import { auth, db, provider } from "./Auth.js";
import { signInWithPopup } from "https://www.gstatic.com/firebasejs/11.5.0/firebase-auth.js";
import { doc, getDoc, setDoc, updateDoc } from "https://www.gstatic.com/firebasejs/11.5.0/firebase-firestore.js";

auth.languageCode = "pt-BR";

// Função central (reutilizável)
async function handleUser(user) {
  const userRef = doc(db, "users", user.uid);
  const userSnap = await getDoc(userRef);

  const now = new Date().toISOString();

  if (!userSnap.exists()) {
    // Novo usuário
    await setDoc(userRef, {
      name: user.displayName || "User",
      email: user.email,
      photo: user.photoURL || null,
      role: "user", // IMPORTANTE (integra com backend)
      createdAt: now,
      lastLogin: now
    });
  } else {
    // Usuário existente
    await updateDoc(userRef, {
      lastLogin: now
    });
  }

  // TOKEN REAL (usar no backend)
  const token = await user.getIdToken();

  // salva só o necessário
  localStorage.setItem("token", token);
  localStorage.setItem("uid", user.uid);

  return true;
}

// Login Google
export async function loginWithGoogle() {
  try {
    const result = await signInWithPopup(auth, provider);
    const user = result.user;

    await handleUser(user);

    window.location.href = "user-dashboard.html";

  } catch (error) {
    console.error("Erro ao fazer login:", error?.message || error);
    alert("Erro ao fazer login com o Google");
  }
}