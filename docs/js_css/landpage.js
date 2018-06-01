var navbar = document.getElementById('navig');

/* Colore la barre de navigation dès qu'elle sort de l'image de fond à cause
   d'un défilement vers le bas, et la rend transparente quand elle y retourne
   à cause d'un défilement vers le haut. */
function updateNav() {
  if (window.scrollY >= window.innerHeight - navbar.clientHeight) {
      navbar.classList.remove("transparent-bg");
      navbar.classList.add("colored-bg");
  } else {
      navbar.classList.remove("colored-bg");
      navbar.classList.add("transparent-bg");
  }
}
/* Appelle updateNav() quand la fenêtre est redimensionnée */
window.addEventListener('resize', updateNav, false)

/* Appelle updateNav() quand l'utilisateur se déplace dans la page */
window.addEventListener('scroll', updateNav, false)
