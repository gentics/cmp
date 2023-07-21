function guideMenu(){
  if (document.getElementById('guides').style.display == "none") {
    document.getElementById('guides').style.display = "block";
    document.getElementById('guidesArrow').innerHTML = "&#9662;";
  } else {
    document.getElementById('guides').style.display = "none";
    document.getElementById('guidesArrow').innerHTML = "&#9656;";
  }
}

function toggle(component) {
  if (document.getElementById(component).style.display == "none") {
    document.getElementById(component).style.display = "block";
    document.getElementById(component + '_nav').classList.add("index");
    sessionStorage.removeItem(component);
  } else {
    document.getElementById(component).style.display = "none";
    document.getElementById(component + '_nav').classList.remove("index");
    sessionStorage.setItem(component, "hidden");
  }
}

function initToggles(...components) {
  components.forEach(component => {
    if (sessionStorage.getItem(component) == "hidden") {
      document.getElementById(component).style.display = "none";
      document.getElementById(component + '_nav').classList.remove("index");
    }
  });
}
