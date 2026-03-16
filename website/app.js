const toggle = document.querySelector(".menu-toggle");
const nav = document.querySelector(".site-nav");

if (toggle && nav) {
  const closeMenu = () => {
    nav.classList.remove("is-open");
    toggle.setAttribute("aria-expanded", "false");
  };

  toggle.addEventListener("click", () => {
    const next = !nav.classList.contains("is-open");
    nav.classList.toggle("is-open", next);
    toggle.setAttribute("aria-expanded", String(next));
  });

  nav.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", closeMenu);
  });

  window.addEventListener("resize", () => {
    if (window.innerWidth > 820) {
      closeMenu();
    }
  });
}
