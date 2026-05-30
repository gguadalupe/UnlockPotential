function initNav() {
  const toggle = document.querySelector("[data-nav-toggle]");
  const nav = document.querySelector("[data-nav]");

  if (!toggle || !nav) {
    return;
  }

  toggle.addEventListener("click", () => {
    const isOpen = nav.classList.toggle("is-open");
    toggle.setAttribute("aria-expanded", String(isOpen));
  });

  nav.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", () => {
      nav.classList.remove("is-open");
      toggle.setAttribute("aria-expanded", "false");
    });
  });
}

function markCurrentNav() {
  const pageKey = document.body.dataset.page;

  if (!pageKey) {
    return;
  }

  document.querySelectorAll("[data-nav-key]").forEach((link) => {
    if (link.dataset.navKey === pageKey) {
      link.setAttribute("aria-current", "page");
    } else {
      link.removeAttribute("aria-current");
    }
  });
}

function updateLanguageLinks() {
  const path = window.location.pathname;
  const isSpanish = /\/es\//.test(path);
  const fileName = path.split("/").pop() || "index.html";
  const pageFile = fileName || "index.html";

  document.querySelectorAll("[data-lang-link]").forEach((link) => {
    const targetLanguage = link.dataset.langLink;

    if (targetLanguage === "es") {
      link.href = isSpanish ? `./${pageFile}` : `./es/${pageFile}`;
      if (isSpanish) {
        link.setAttribute("aria-current", "true");
      } else {
        link.removeAttribute("aria-current");
      }
    }

    if (targetLanguage === "en") {
      link.href = isSpanish ? `../${pageFile}` : `./${pageFile}`;
      if (isSpanish) {
        link.removeAttribute("aria-current");
      } else {
        link.setAttribute("aria-current", "true");
      }
    }
  });
}

async function loadPartials() {
  const includes = document.querySelectorAll("[data-include]");

  for (const node of includes) {
    const response = await fetch(node.dataset.include);

    if (!response.ok) {
      throw new Error(`Failed to load partial: ${node.dataset.include}`);
    }

    node.outerHTML = await response.text();
  }
}

function updateYear() {
  document.querySelectorAll("[data-year]").forEach((node) => {
    node.textContent = String(new Date().getFullYear());
  });
}

async function initSite() {
  try {
    await loadPartials();
  } catch (error) {
    console.error(error);
  }

  markCurrentNav();
  updateLanguageLinks();
  initNav();
  updateYear();
}

initSite();
