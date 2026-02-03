
// firestoreService.js
import { db } from "./firebase.js";
import { collection, getDocs, addDoc, updateDoc, doc, query, where } from "firebase/firestore";

export async function getCollection(name) {
  const snapshot = await getDocs(collection(db, name));
  return snapshot.docs.map(d => d.data());
}

export async function addDocument(name, data) {
  return await addDoc(collection(db, name), data);
}

export async function updateDocument(ref, data) {
  return await updateDoc(ref, data);
}

export async function findDocumentByField(name, field, value) {
  const q = query(collection(db, name), where(field, "==", value));
  const snapshot = await getDocs(q);
  return snapshot.docs[0]; // undefined se não achar
}
