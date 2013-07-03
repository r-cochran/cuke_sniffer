function toggleById(item, link) {
    updateDisplayStatus(document.getElementById(item));
    toggleText(link)
}
function updateDisplayStatus(object) {
    object.style.display = (object.style.display == "block") ? 'none' : "block";
}
function toggleText(link) {
    var char_result = link.innerHTML.indexOf("+") > -1 ? "-" : "+";
    link.innerHTML = link.innerHTML.replace(/(\+|\-)/, char_result)
}