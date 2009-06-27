/**
 *  toggle class content
 */
function toggle_class_content(elem, selector) {
  var target = $(selector);
  var labels = ['more&raquo;', '&laquo;close'];
  var index = target.css('display') == 'none' ? 1 : 0;
  //$(elem).html(labels[index]);
  //$(target).slideToggle(500);
  $(target).slideToggle(500, function() { $(elem).html(labels[index]); });
}


/**
 *  toggle method content
 */
function toggle_method_content(elem) {
  //var tr = $(elem).parent().parent().next();
  var tr = $(elem).parents('tr').next();
  _toggle_method_content(tr);
}

function hide_method_content(elem) {
  //var tr = $(elem).parent().parent().parent();
  var tr = $(elem).parents('tr');
  _toggle_method_content(tr);
}
  
function _toggle_method_content(tr) {
  //jQuery.data(tr, "olddisplay", "table-row");
  var div = $('div', tr);
  var msec = 500;
  if (tr.css('display') == 'none') {
    tr.css('display', null);
    div.slideDown(msec);
  }
  else {
    //div.slideUp(2000);
    //tr.get(0).style.display = 'none';
    div.slideUp(msec, function() { tr.css('display', 'none'); });
  }
}

