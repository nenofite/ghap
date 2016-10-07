import js.JQuery;

class Dia
{
  static var dias : Array<Dia> = new Array();

  public var showing(default, null) : Bool;
  var el : JQuery;

  public function new(id : String, showing = false)
  {
    this.showing = showing;
    el = new JQuery("#" + id);

    resize();
    
    dias.push(this);
  }
  
  /// Sets the div's height and recenters it based upon window.innerHeight,
  /// giving it at least a 25px padding
  public function resize()
  {
    var h = el.height();
    
    var maxHeight = Math.round(js.Browser.window.innerHeight) - 50;
    (cast el.css)("max-height", maxHeight + "px");
    if (h > maxHeight) {
      h = maxHeight;
    }

    h = Math.round(h / 2);
    (cast el.css)("margin-top", -h + "px");
  }
  
  /// Calls resize() on all constructed Dias
  public static function resizeAll()
  {
    for (d in dias) d.resize();
  }

  public function bind(bindings : Dynamic<Void -> Void>)
  {
    for (c in el.find("a[data-bind]")) {
      var b = c.attr("data-bind");
      var fn = Reflect.field(bindings, b);
      if (fn == null) throw "Unsatisfied binding: " + b + " in " + el.attr("id");
      c.click(fn);
    }
  }

  public function show()
  {
    if (!showing) {
      showing = true;
      //~ Ad.show();
      el.addClass("a");
      (cast js.Browser.window).setTimeout(function() {
        if (showing) el.addClass("b");
      }, 100);
    }
  }

  public function hide()
  {
    if (showing) {
      showing = false;
      //~ hideAd();
      el.removeClass("b");
      (cast js.Browser.window).setTimeout(function() {
        if (!showing) el.removeClass("a");
      }, 500);
      
      View.v.canvas.focus();
    }
  }
  
  //~ static function hideAd()
  //~ {
    //~ var allHidden = true;
    //~ for (dia in dias) {
      //~ if (dia.showing) {
        //~ allHidden = false;
        //~ break;
      //~ }
    //~ }
    //~ if (allHidden) Ad.hide();
  //~ }

  public function toggle()
  {
    if (showing) hide() else show();
  }
}

//~ class Ad
//~ {
  //~ static var showing : Bool;
  //~ static var el : JQuery;
  //~ 
  //~ public static function init()
  //~ {
    //~ el = new js.JQuery("#ad_dia");
    //~ showing = false;
  //~ }
  //~ 
  //~ public static function show()
  //~ {
    //~ if (!showing) {
      //~ showing = true;
      //~ el.addClass("a");
      //~ (cast js.Browser.window).setTimeout(function() {
        //~ if (showing) el.addClass("b");
      //~ }, 100);
    //~ }
  //~ }
  //~ 
  //~ public static function hide()
  //~ {
    //~ if (showing) {
      //~ showing = false;
      //~ el.removeClass("b");
      //~ (cast js.Browser.window).setTimeout(function() {
        //~ if (!showing) el.removeClass("a");
      //~ }, 500);
      //~ 
      //~ View.v.canvas.focus();
    //~ }
  //~ }
//~ }
