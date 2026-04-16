
import { auth } from "../Auth.js";
import ADN from "./app.js";

import { onAuthStateChanged } from "https://www.gstatic.com/firebasejs/11.5.0/firebase-auth.js";

let currentUser = null;
let authReady = false;
let cachedToken = null;


onAuthStateChanged(auth, async (user) => {
  currentUser = user;
  authReady = true;

  console.log("Auth carregado:", user?.email);

  if (!user) {
    ADN.run("alert", { text: "Faça login para usar o sistema" });
    return;
  }

  try {
    const token = await user.getIdToken();
    cachedToken = token;

    localStorage.setItem("token", token);

    loadAnalysts();

  } catch (err) {
    console.error("Erro ao pegar token:", err);
      ADN.run("alert", {
      text: "Erro ao pegar token"
    });
  }
});


async function getAuthHeaders() {
  if (!authReady) {
    throw new Error("Auth ainda carregando...");
  }

  if (!currentUser) {
    throw new Error("Usuário não logado");
  }

  const token = await currentUser.getIdToken(true);

  return {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${token}`
  };
}

async function handleResponse(res) {
  const data = await res.json();

  if (!res.ok || data.success === false) {
    throw new Error(data.message || "Erro desconhecido");
  }

  return data;
}

const container = document.getElementById("data-center");
// =========================
// ADD ANALYST
// =========================

function formatTime(ms) {
  let totalSeconds = Math.floor(ms / 1000);

  const years = Math.floor(totalSeconds / (86400 * 365));
  totalSeconds %= (86400 * 365);

  const days = Math.floor(totalSeconds / 86400);
  totalSeconds %= 86400;

  const hours = Math.floor(totalSeconds / 3600);
  totalSeconds %= 3600;

  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;

  const pad = (n) => String(n).padStart(2, "0");

  return `${pad(years)}:${pad(days)}:${pad(hours)}:${pad(minutes)}:${pad(seconds)}`;
}

function formatTimeSmart(ms) {
  let totalSeconds = Math.floor(ms / 1000);

  const years = Math.floor(totalSeconds / (86400 * 365));
  totalSeconds %= (86400 * 365);

  const days = Math.floor(totalSeconds / 86400);
  totalSeconds %= 86400;

  const hours = Math.floor(totalSeconds / 3600);
  totalSeconds %= 3600;

  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;

  return `
    ${years ? years + "y " : ""}
    ${days ? days + "d " : ""}
    ${hours ? hours + "h " : ""}
    ${minutes ? minutes + "m " : ""}
    ${seconds}s
  `.trim();
}

function formatTimeAdvanced(startTime, options = {}) {
  const now = new Date();
  const start = new Date(startTime);

  let diff = Math.floor((now - start) / 1000); // segundos totais

  const years = Math.floor(diff / (365 * 24 * 3600));
  diff %= (365 * 24 * 3600);

  const days = Math.floor(diff / (24 * 3600));
  diff %= (24 * 3600);

  const hours = Math.floor(diff / 3600);
  diff %= 3600;

  const minutes = Math.floor(diff / 60);
  const seconds = diff % 60;

  const pad = (n) => String(n).padStart(2, "0");

  // formato técnico fixo
  const full = `${pad(years)}:${pad(days)}:${pad(hours)}:${pad(minutes)}:${pad(seconds)}`;

  // formato inteligente
  const smart = [
    years && `${years}y`,
    days && `${days}d`,
    hours && `${hours}h`,
    minutes && `${minutes}m`,
    `${seconds}s`
  ]
    .filter(Boolean)
    .join(" ");

  return {
    full,
    smart,
    raw: { years, days, hours, minutes, seconds }
  };
}

async function addAnalyst() {
  const nameInput = document.getElementById("name");
  const roleInput = document.getElementById("role");

  const name = nameInput.value.trim();
  const role = roleInput.value.trim();

  if (!name || !role) {
    ADN.run("alert", { text: "Preencha os campos" });
    return;
  }

  try {
    const headers = await getAuthHeaders();

    const res = await fetch("/analysts/add", {
      method: "POST",
      headers,
      body: JSON.stringify({ name, role })
    });

    const data = await handleResponse(res);

    ADN.run("alert", {
      text: data.message
    });

    nameInput.value = "";
    roleInput.value = "";

    loadAnalysts();

  } catch (err) {
    console.error(err);

    ADN.run("alert", {
      text: err.message
    });
  }
}

// =========================
// TOGGLE WORK (PONTO)
// =========================
async function toggle(id) {
  try {
    const headers = await getAuthHeaders();

    const res = await fetch(`/analysts/${id}/toggle`, {
      method: "POST",
      headers
    });

    const data = await handleResponse(res);

    ADN.run("alert", {
      text: data.message
    });

    loadAnalysts();

  } catch (err) {
    ADN.run("alert", {
      text: err.message
    });
  }
}

// =========================
// ATIVAR / DESATIVAR
// =========================
async function toggleActive(id) {
  try {
    const headers = await getAuthHeaders();

    const res = await fetch(`/analysts/${id}/active`, {
      method: "PUT",
      headers
    });

    const data = await handleResponse(res);

    ADN.run("alert", {
      text: data.message || "Status atualizado"
    });

    loadAnalysts();

  } catch (err) {
    ADN.run("alert", {
      text: err.message
    });
  }
}
// =========================
// REMOVER
// =========================
async function removeAnalyst(id) {

  ADN.run("confirm", {
    text: "Tem certeza que deseja remover este analista?",

  onYes: async () => {
  try {
    const headers = await getAuthHeaders();

    const res = await fetch(`/analysts/${id}`, {
      method: "DELETE",
      headers
    });

    const data = await handleResponse(res);

    ADN.run("alert", {
      text: data.message
    });

    loadAnalysts();

  } catch (err) {
    ADN.run("alert", {
      text: err.message
    });
  }
},

    onNo: () => {
      ADN.run("alert", {
        text: "Ação cancelada"
      });
    }

  });

}
// =========================
// LOAD ANALYSTS
// =========================
async function loadAnalysts() {
  const headers = await getAuthHeaders();

  const res = await fetch("/analysts", {
  headers
  });
  const data = await res.json();

  container.innerHTML = "";

  data.analysts.forEach(a => {
    const div = document.createElement("div");
    div.className = "card";

    // tempo trabalhando
    let tempo = "";
    if (a.working && a.lastCheckIn) {
      const diff = Date.now() - a.lastCheckIn;
      const tempoFormatado = formatTime(diff);
      const time = formatTimeAdvanced(a.lastCheckIn);
      tempo = `
<p>
  ⏱️ <span data-time="${a.lastCheckIn}">
    ${tempoFormatado}
  </span>
</p>

`;
    }

    div.innerHTML = `
  <h3><i class="fa-solid fa-user"></i> ${a.name}</h3>
  <p><i class="fa-solid fa-briefcase"></i> ${a.role}</p>

  <p>Status: 
    <span class="${a.working ? "status-on" : "status-off"}">
      <i class="fa-solid ${a.working ? "fa-circle-play" : "fa-circle-stop"}"></i>
      ${a.working ? "Trabalhando" : "Offline"}
    </span>
  </p>

  ${tempo}

  <p>
    <i class="fa-solid fa-toggle-${a.active ? "on" : "off"}"></i>
    Ativo: ${a.active ? "Sim" : "Não"}
  </p>

  <button onclick="toggle('${a.id}')">
    <i class="fa-solid ${a.working ? "fa-stop" : "fa-play"}"></i>
    ${a.working ? "Encerrar" : "Iniciar"}
  </button>

  <button onclick="toggleActive('${a.id}')">
    <i class="fa-solid fa-power-off"></i>
    ${a.active ? "Desativar" : "Ativar"}
  </button>

  <button onclick="removeAnalyst('${a.id}')">
    <i class="fa-solid fa-trash"></i> Remover
  </button>
`;

    container.appendChild(div);
  });
}

// =========================
// AUTO REFRESH
// =========================
//setInterval(loadAnalysts, 5000);


// timer local (atualiza só o tempo sem refetch)
setInterval(() => {
  document.querySelectorAll("[data-time]").forEach(el => {
    const start = parseInt(el.dataset.time);
    const diff = Date.now() - start;
    el.innerText = formatTime(diff);
  });
}, 1000);

// =========================
// INIT Token R
// =========================

//loadAnalysts();

// =========================
// GLOBAL (IMPORTANTE p/ HTML)
// =========================
window.addAnalyst = addAnalyst;
window.toggle = toggle;
window.toggleActive = toggleActive;
window.removeAnalyst = removeAnalyst;