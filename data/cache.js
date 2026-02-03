// ./data/cache.js

const memory = Object.create(null);

/**
 * Salva um valor em cache
 * @param {string} key
 * @param {any} value
 * @param {number} ttl Tempo em ms (opcional)
 */
export function setCache(key, value, ttl = null) {
  const expiresAt = ttl ? Date.now() + ttl : null;

  memory[key] = {
    value,
    expiresAt
  };
}

/**
 * Recupera valor do cache
 * @param {string} key
 * @returns {any|null}
 */
export function getCache(key) {
  const data = memory[key];
  if (!data) return null;

  // TTL expirado
  if (data.expiresAt && Date.now() > data.expiresAt) {
    delete memory[key];
    return null;
  }

  return data.value;
}

/**
 * Remove uma chave do cache
 */
export function deleteCache(key) {
  delete memory[key];
}

/**
 * Limpa todo cache
 */
export function clearCache() {
  for (const key in memory) {
    delete memory[key];
  }
}

/**
 * Debug / métricas
 */
export function getCacheStats() {
  return {
    keys: Object.keys(memory).length
  };
}
