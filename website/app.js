const yearTarget = document.getElementById("site-year");
const mobileNavToggle = document.querySelector(".mobile-nav-toggle");
const mobileNavPanel = document.getElementById("mobile-nav-panel");
const mobileNavLinks = document.querySelectorAll(".topnav-mobile a");

if (yearTarget) {
  yearTarget.textContent = new Date().getFullYear().toString();
}

if (mobileNavToggle && mobileNavPanel) {
  const setMobileNavState = (open) => {
    mobileNavToggle.setAttribute("aria-expanded", open ? "true" : "false");
    mobileNavPanel.setAttribute("data-open", open ? "true" : "false");
  };

  mobileNavToggle.addEventListener("click", () => {
    const isOpen = mobileNavToggle.getAttribute("aria-expanded") === "true";
    setMobileNavState(!isOpen);
  });

  mobileNavLinks.forEach((link) => {
    link.addEventListener("click", () => {
      setMobileNavState(false);
    });
  });

  window.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      setMobileNavState(false);
    }
  });

  window.addEventListener("resize", () => {
    if (window.innerWidth > 820) {
      setMobileNavState(false);
    }
  });
}
