// backend/services/appsService.js

import { dbAdmin } from "./firebaseAdmin.js";
import { getCache, setCache } from "../data/cache.js";

const CACHE_KEY = "apps:list";
const CACHE_TTL = 30_000; // 30s

export async function getAppsCached() {
  const cached = getCache(CACHE_KEY);
  if (cached) return cached;

  const snapshot = await dbAdmin.collection("apps").get();
  const data = snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));

  setCache(CACHE_KEY, data, CACHE_TTL);
  return data;
}

export function invalidateAppsCache() {
  setCache(CACHE_KEY, null, 1);
}
