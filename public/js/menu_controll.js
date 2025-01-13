let menuButton = document.querySelector(".menu-buttons");
menuButton.addEventListener("click", showMenu);

let layer = document.querySelector(".fade-menu");
layer.addEventListener("click", showMenu);

let isOpened = false;

let screenWidth = 0;

window.addEventListener('resize', () => {
    screenWidth = document.documentElement.clientWidth;
    if (screenWidth > 1000 && isOpened) {
        showMenu();
    };
});


function showMenu() {
    isOpened = !isOpened;
    let nav = document.querySelector("menu");
    nav.classList.toggle("show");
    layer.classList.toggle("visible");

    let menuBar = document.querySelector(".menu-open");
    let xButton = document.querySelector(".menu-close");
    if (menuBar.style.display == "none") {
        menuBar.style.display = "block";
        xButton.style.display = "none";
    } else {
        menuBar.style.display = "none";
        xButton.style.display = "block";
    }

};


window.onscroll = () => {
    let navbar = document.querySelector('nav');
    navbar.classList.toggle('sticky', window.scrollY > 25);

    if (isOpened) {
        showMenu();
    };
};
