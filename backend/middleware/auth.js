import admin from "firebase-admin";
import { db } from "../firebase.js";

export async function verifyAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "No token" });
    }

    const token = authHeader.split("Bearer ")[1];
    const decoded = await admin.auth().verifyIdToken(token);

    let role = "user"; // default seguro

    try {
      const userRef = db.collection("users").doc(decoded.uid);
      const userSnap = await userRef.get();

      if (userSnap.exists) {
        const data = userSnap.data();

        // 🔒 só aceita role válida
        if (data.role && typeof data.role === "string") {
          role = data.role;
        }
      }
    } catch (err) {
      console.warn("Erro ao buscar role:", err);
      // não quebra auth por causa disso
    }

    req.user = {
      uid: decoded.uid,
      email: decoded.email,
      name: decoded.name || "Unknown",
      role
    };

    next();

  } catch (err) {
    console.error("Auth error:", err);
    return res.status(401).json({ error: "Invalid token" });
  }
}

export function requireAdmin(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ error: "not authenticated" });
  }

  if (req.user.role !== "admin") {
    return res.status(403).json({ error: "forbidden" });
  }

  next();
}