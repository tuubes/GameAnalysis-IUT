// Ne charge le contenu des tabs que lorsqu'ils sont activés, pour éviter de
// surcharger le client (navigateur) et le serveur shiny.

$('a[data-toggle="pill"]').on('shown.bs.tab', function(e) {
  $(e.target.hash).find('.lazy').each(function() {
    var src = $(this).attr('lazy-src');
    var load = $(this).attr('lazy-onload');
    $(this).attr("src", src).removeAttr('lazy-src').attr("onload", load);
  })
});

/*
$('iframe').each(function(i, obj){
  alert(i + "" + obj)
  $(obj).ready(function() {
    var spinner = $(obj).attr('spin');
    $(spinner).attr("display", "none");
    alert("Loaded" + obj + "; Hidden " + spinner);
  });
})
*/

function hide(e) {
  $(e).attr("display", "none").attr("visibility", "hidden");
  $(e).removeClass("fa").removeClass("fa-spinner").removeClass("fa")
}
