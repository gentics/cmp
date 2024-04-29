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
  if (sessionStorage.getItem(component) == "hidden") {
    // show
    const divs = document.getElementsByClassName("component_" + component);
    for (let i = 0; i < divs.length; i++) {
      divs[i].style.display = "block";
    }
    document.getElementById(component + '_nav').classList.add("index");
    sessionStorage.removeItem(component);
  } else {
    // hide
    const divs = document.getElementsByClassName("component_" + component);
    for (let i = 0; i < divs.length; i++) {
      divs[i].style.display = "none";
    }
    document.getElementById(component + '_nav').classList.remove("index");
    sessionStorage.setItem(component, "hidden");
  }
}

function initToggles(...components) {
  // if a query parameter "show" is contained in the URL, we show exactly the requested components
  const searchParams = new URLSearchParams(window.location.search);
  if (searchParams.has("show")) {
    const showParam = searchParams.get("show");
    const showComponents = showParam.split(",");
    components.forEach(component => {
      if (showComponents.includes(component)) {
        sessionStorage.removeItem(component);
      } else {
        sessionStorage.setItem(component, "hidden");
      }
    });
  }

  components.forEach(component => {
    if (sessionStorage.getItem(component) == "hidden") {
      const divs = document.getElementsByClassName("component_" + component);
      for (let i = 0; i < divs.length; i++) {
        divs[i].style.display = "none";
      }
      // document.getElementById(component).style.display = "none";
      document.getElementById(component + '_nav').classList.remove("index");
    }
  });
}
