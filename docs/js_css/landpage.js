var navbar = document.getElementById('navig');

/* Colore la barre de navigation dès qu'elle sort de l'image de fond à cause
   d'un défilement vers le bas, et la rend transparente quand elle y retourne
   à cause d'un défilement vers le haut. */
window.onscroll = function () {
    if (window.scrollY >= window.innerHeight - navbar.clientHeight) {
        navbar.classList.remove("transparent-bg");
        navbar.classList.add("colored-bg");
    } else {
        navbar.classList.remove("colored-bg");
        navbar.classList.add("transparent-bg");
    }
};
