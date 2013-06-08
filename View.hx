using Utils;

import js.JQuery;

class View
{
  public static inline var ViewDist = 10;
  public static inline var XPadding = 250;
  public static inline var YPadding = 100;
  
  public static var v : View;

  static var requestAnimationFrame = function(f) untyped __js__("(window.requestAnimationFrame || window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame)(f)");

  public var canvas : Dynamic;
  var context : Dynamic;
  //~ var stats : Dynamic;
  var cmp_needle : Dynamic;
  var span_seed : Dynamic;
  var inp_seed : Dynamic;
  public var achievements : Dynamic;
  var selectionDiv : Dynamic;
  var sel_name : Dynamic;
  var sel_level : Dynamic;
  public var ul_achv : Dynamic;

  var viewX : Int = 0;
  var viewY : Int = 0;

  var viewW : Int = -1;
  var viewH : Int = -1;
  
  var selection : Ent = null;

  var factory : World.Factory;
  public var world : World;

  var prevTime : Float;

  public var binder : KeyBinder;
  var dragStart : { x : Int, y : Int } = null;
  var mousePos : { x : Int, y : Int };
  var arrowKey : Null<Dir> = null;

  var showElevation : Bool = false;
  var showGrid : Bool = false;

  // dialogs:
  var dia_instructions : Dia;
  var dia_win : Dia;
  var dia_lose : Dia;
  var dia_loading : Dia;
  var dia_seed : Dia;
  var dia_change_seed : Dia;
  public var dia_achievements : Dia;
  var dia_about : Dia;
  
  // move arrows:
  public var arr_u : Dynamic;
  public var arr_ur : Dynamic;
  public var arr_r : Dynamic;
  public var arr_dr : Dynamic;
  public var arr_d : Dynamic;
  public var arr_dl : Dynamic;
  public var arr_l : Dynamic;
  public var arr_ul : Dynamic;
  public var arr_w : Dynamic;
  
  public var btn_dismount : Dynamic;

  // stats:
  var s_tiles : Int;
  var s_sprites : Int;
  var s_overlays : Int;

  var resized : Bool = false;
  
  var bgPattern : Dynamic;

  public function new(canvasId : String)
  {
    v = this;
  
    canvas = js.Lib.document.getElementById(canvasId);
    //~ stats = js.Lib.document.getElementById("stats");
    cmp_needle = js.Lib.document.getElementById("cmp_needle");
    span_seed = js.Lib.document.getElementById("seed");
    inp_seed = js.Lib.document.getElementById("inp_seed");
    achievements = js.Lib.document.getElementById("achievements");
    selectionDiv = js.Lib.document.getElementById("selection");
    sel_name = js.Lib.document.getElementById("sel_name");
    sel_level = js.Lib.document.getElementById("sel_level");
    ul_achv = js.Lib.document.getElementById("ul_achv");

    //~ viewW = canvas.width = js.Lib.window.innerWidth;
    //~ viewH = canvas.height = js.Lib.window.innerHeight;
    //~ viewW = canvas.width = (cast js.Lib.window).clientWidth;
    //~ viewH = canvas.height = (cast js.Lib.window).clientHeight;
    js.Lib.window.onresize = function(ev) {
      resized = true;
      world.makeDirty();
    };

    context = canvas.getContext("2d");

    bgPattern = context.createPattern(Images.i.background, "repeat");

    mousePos = { x: 0, y: 0 };

    canvas.addEventListener("mousedown", function(ev) {
      if (ev.which == 1) {
        ev.preventDefault();
        canvas.focus();
        
        var gridX = Math.floor((ev.clientX + viewX) / Terrain.spriteW);
        var gridY = Math.floor((ev.clientY + viewY) / Terrain.spriteH);
        var ent = world.entAt2(gridX, gridY);
        if (ent != null) select(ent) else if (selection != null) deselect();
      }
    });
    canvas.addEventListener("touchstart", function(ev) {
      ev.preventDefault();
      var t = ev.targetTouches[0];
      canvas.focus();
      
      var gridX = Math.floor((t.clientX + viewX) / Terrain.spriteW);
      var gridY = Math.floor((t.clientY + viewY) / Terrain.spriteH);
      var ent = world.entAt2(gridX, gridY);
      if (ent != null) select(ent) else if (selection != null) deselect();
    });

    var mouseup = function(ev) {
      dragStart = null;
    };

    var c = new JQuery(canvas);
    //~ c.bind("mouseup mouseleave touchend touchleave touchcancel", mouseup);
//~ 
    //~ // touchmove
    //~ c.bind("mousemove", function(ev) {
      //~ ev.preventDefault();
//~ 
      //~ mousePos.x = ev.pageX;
      //~ mousePos.y = ev.pageY;
//~ 
      //~ if (dragStart != null) world.makeDirty();
    //~ });

    //~ canvas.addEventListener("touchmove", function(ev) {
      //~ ev.preventDefault();
//~ 
      //~ var t = (cast ev).targetTouches[0];
//~ 
      //~ mousePos.x = t.clientX;
      //~ mousePos.y = t.clientY;
//~ 
      //~ if (dragStart != null) world.makeDirty();
    //~ });

    dia_win = new Dia("dia_win");
    dia_win.bind({ close: dia_win.hide, restart: restartGame });
    dia_lose = new Dia("dia_lose");
    dia_lose.bind({ restart: restartGame });
    dia_instructions = new Dia("dia_instructions");
    dia_instructions.bind({ close: dia_instructions.hide });
    dia_loading = new Dia("dia_loading", true);
    dia_seed = new Dia("dia_seed");
    dia_seed.bind({ close: dia_seed.hide, change: function() { dia_seed.hide(); dia_change_seed.show(); } });
    dia_change_seed = new Dia("dia_change_seed");
    dia_change_seed.bind({ cancel: dia_change_seed.hide, accept: readSeed });
    dia_achievements = new Dia("dia_achievements");
    dia_achievements.bind({ close: dia_achievements.hide });
    dia_about = new Dia("dia_about");
    dia_about.bind({ close: dia_about.hide });

    arr_u = js.Lib.document.getElementById("arr_u");
    arr_ur = js.Lib.document.getElementById("arr_ur");
    arr_r = js.Lib.document.getElementById("arr_r");
    arr_dr = js.Lib.document.getElementById("arr_dr");
    arr_d = js.Lib.document.getElementById("arr_d");
    arr_dl = js.Lib.document.getElementById("arr_dl");
    arr_l = js.Lib.document.getElementById("arr_l");
    arr_ul = js.Lib.document.getElementById("arr_ul");
    arr_w = js.Lib.document.getElementById("arr_w");
    
    btn_dismount = js.Lib.document.getElementById("btn_dismount");

    binder = new KeyBinder();
    //~ binder.bind('H', function() {
      //~ showElevation = !showElevation;
      //~ world.makeDirty();
    //~ });
    //~ binder.bind('G', function() {
      //~ showGrid = !showGrid;
      //~ world.makeDirty();
    //~ });
    binder.bind(191, dia_instructions.show); // '?'
    binder.bind(65, dia_achievements.show); // 'a'
    //~ binder.bind(69, function() { // 'e'
    //~ });
    
    //~ binder.uncaught(function(k) throw "Key: " + k);

    c.bind("keydown", function(ev) binder.call(ev.which));

    js.Lib.document.getElementById("btn_inst").onclick = cast dia_instructions.show;
    js.Lib.document.getElementById("btn_seed").onclick = cast dia_seed.show;
    js.Lib.document.getElementById("btn_achv").onclick = cast dia_achievements.show;
    js.Lib.document.getElementById("btn_about").onclick = cast dia_about.show;

    Terrain.init();
    Ent.Player.init();

    Ent.Player.p.addBindings(this);

    factory = World.Factory.makeDefault();

    genWorld(Std.random(9999));

    //~ var seedI = new Input<Int>("Seed", world.originalSeed, Std.parseInt);
    //~ seedI.onChange = function(v) {
      //~ genWorld(v);
      //~ draw();
    //~ };
  }

  public static function main()
  {
    new JQuery(js.Lib.document).ready(
      cast function() Images.init(function() {
        trace("Loading complete.");
        var v = new View("canv");
        v.draw();
        v.doneLoading();
      })
    );
  }

  function resize()
  {
    viewW = canvas.width = js.Lib.window.innerWidth ;
    viewH = canvas.height = js.Lib.window.innerHeight;
    
    Dia.resizeAll();

    world.makeDirty();
  }

  function restartGame()
  {
    var b = js.Lib.document.getElementById("battle");
    b.innerHTML = "";
    dia_win.hide();
    dia_lose.hide();
    Ent.Player.p.reset();
    genWorld(Std.random(9999));
  }

  function readSeed()
  {
    var text = inp_seed.value.trim();
    var num = Std.parseInt(text);
    if ("" + num == text) {
      genWorld(num);
      dia_change_seed.hide();
    }
  }

  function genWorld(seed)
  {
    Ent.Player.p.coord = null;

    world = factory.generate(seed);

    span_seed.innerHTML = inp_seed.value = "" + seed;

    world.onDirty = function() {
      requestAnimationFrame(animate);
    };

    var b = js.Lib.document.getElementById("battle");
    var wrap = { ls: new Array<Dynamic>() };

    world.clearLog = function() {
      var clears = wrap.ls;
      wrap.ls = new Array<Dynamic>();

      for (el in clears) {
        el.className += " closing";
      }

      (cast js.Lib.window).setTimeout(function() { for (el in clears) b.removeChild(el); }, 1000);
    };
    world.log = function(l) {
      var li = js.Lib.document.createElement("li");

      switch (l) {
      case Error(s):
        li.className = "error";
        li.innerHTML = s;
      case Battle(s):
        li.className = "fight";
        li.innerHTML = s;
      case Xp(s):
        li.className = "xp";
        li.innerHTML = s;
      }

      b.insertBefore(li, b.firstChild);
      wrap.ls.push(li);
    };

    world.win = dia_win.show;
    world.lose = dia_lose.show;

    resize();

    lookAt(Ent.Player.p.coord);
  }

  public function lookAt(c : World.Coord)
  {
    viewX = Math.round(c.x * Terrain.spriteW - viewW / 2);
    viewY = Math.round(c.y * Terrain.spriteH - viewH / 2);
    world.makeDirty();
  }

  public function draw()
  {
    s_tiles = s_sprites = s_overlays = 0;

    var grid = world.iterGrid().map(Utils.flatten).flatten();

    context.fillStyle = bgPattern;
    context.fillRect(0, 0, viewW, viewH);

    var startX = Math.floor(viewX / Terrain.spriteW);
    var startY = Math.floor(viewY / Terrain.spriteH);
    var offX = viewX - startX * Terrain.spriteW;// % Terrain.spriteW;
    var offY = viewY - startY * Terrain.spriteH;// % Terrain.spriteH;

    var vWidth = Math.ceil(viewW / Terrain.spriteW) + 1;
    var vHeight = Math.ceil(viewH / Terrain.spriteH) + 1;

    var endX = startX + vWidth;
    var endY = startY + vHeight;

    var rowLen = grid[0].length;

    var skull = Images.i.skull;
    var skullW = Math.floor(skull.width / 2);
    var skullH = skull.height;

    // Draw base tiles
    for (y in 0...vHeight) {
      var ay = startY + y;
      if (ay < 0 || ay >= grid.length) {
      } else {
        var r = grid[ay];
        for (x in 0...vWidth) {
          var ax = startX + x;
          if (ax >= 0 && ax < rowLen) {
            var dist = { x: ax, y: ay }.distanceTo(Ent.Player.p.coord);
            var tile = r[ax];
            var lx = x * Terrain.spriteW - offX;
            var ly = y * Terrain.spriteH - offY;
            if (showElevation) {
              var e = Math.round(tile.elevation * 255 / 100);
              context.fillStyle = "rgb(" + e + "," + e + "," + e + ")";
              context.fillRect(lx, ly, Terrain.spriteW, Terrain.spriteH);
            } else {
              context.drawImage(tile.type.tile, lx, ly);
              
              if (selection != null) {
                var selCoord = selection.coord;
                if (selCoord.distanceTo({ x: ax, y: ay }) <= selection.viewDist) {
                  context.fillStyle = "rgba(255, 0, 0, 0.25)";
                  context.fillRect(lx, ly, Terrain.spriteW, Terrain.spriteH);
                }
              }
              
              var diff = dist - ViewDist;
              if (diff > 0) {
                context.fillStyle = "black";
                context.globalAlpha = if (diff > 3) 1 else 0.5 + diff / 3 / 2;
                context.fillRect(lx, ly, Terrain.spriteW, Terrain.spriteH);
                context.globalAlpha = 1;
              }
            }
            if (showGrid) {
              context.strokeStyle = "black";
              context.strokeRect(lx, ly, Terrain.spriteW, Terrain.spriteH);
            }
            ++s_tiles;
          }
        }
      }
    }

    // Draw sprites and fog
    for (y in 0...vHeight) {
      var ay = startY + y;
      if (ay >= 0 && ay < grid.length) {
        var r = grid[ay];
        for (x in 0...vWidth) {
          var ax = startX + x;
          if (ax >= 0 && ax < rowLen) {
            var dist = { x: ax, y: ay }.distanceTo(Ent.Player.p.coord);
            if (dist <= ViewDist) {
              var spr = r[ax].type.getSprite(randFor(ax, ay));

              /// lx and ly are the center of the current tile
              var lx = x * Terrain.spriteW - offX + Math.floor(Terrain.spriteW / 2);
              var ly = y * Terrain.spriteH - offY + Math.floor(Terrain.spriteH / 2);

              var ent = world.entAt2(ax, ay);
              var hasEnt = ent != null;

              if (hasEnt) {
                context.globalAlpha = 0.5;
              }

              var sprite = spr.sprite;
              if (sprite != null) {
                context.drawImage(sprite, lx + Math.floor(spr.x - sprite.width / 2), ly + Math.floor(spr.y - sprite.height));
                ++s_sprites;
              }

              context.globalAlpha = 1;

              if (hasEnt) {
                if (selection == ent) {
                  var selImg = Images.i.selection;
                  context.drawImage(selImg, lx - Math.round(selImg.width / 2), ly - Math.round(selImg.height / 2));
                }
              
                if (!ent.alive) context.globalAlpha = 0.75;
                var img = ent.sprite;
                context.drawImage(img, lx - Math.floor(img.width / 2), ly - img.height);
                if (!ent.alive) {
                  context.globalAlpha = 1;
                  context.drawImage(skull, lx - skullW, ly - skullH);
                }
                ++s_overlays;
              }
            }
          }
        }
      }
    }

    showStats();
  }

  function showStats()
  {
    //~ stats.innerHTML = "T: " + s_tiles + ", S: " + s_sprites + ", O: " + s_overlays +
                      //~ "<br/> Ents: " + Lambda.count(world.ents);
  }

  function animate(/*time : Float*/) {
    //if (dragStart != null) {
      //viewX -= mousePos.x - dragStart.x;
      //viewY -= mousePos.y - dragStart.y;
      //dragStart.x = mousePos.x;
      //dragStart.y = mousePos.y;
      ////~ keep = true;
    //}
    if (resized) resize();
    lookAt(Ent.Player.p.coord);
    if (selection != null) updateSelection();
    draw();
    updateCompass();
    world.makeClean();
  }

  function updateCompass()
  {
    var dir = Ent.Player.p.coord.directionTo(Ent.panda.coord);
    var degs = switch (dir.x) {
      case -1:
        switch (dir.y) {
        case -1: "-45";
        case 0: "-90";
        case 1: "-135";
        }
      case 0:
        switch (dir.y) {
        case -1: "0";
        case 1: "180";
        }
      case 1:
        switch (dir.y) {
        case -1: "45";
        case 0: "90";
        case 1: "135";
        }
      };
    cmp_needle.style.transform = cmp_needle.style.webkitTransform = "rotate(" + degs + "deg)";
  }
  
  /// Assuming selection is not null:
  /// If selection's coord is null or outside of Player's view, calls
  /// deselect() and returns
  /// Places the selection box over where the Ent is on-screen
  /// Writes Ent's name and level inside the selection box
  function updateSelection()
  {
    var c = selection.coord;
    if (c == null || c.distanceTo(Ent.Player.p.coord) > ViewDist) {
      deselect();
      return;
    }
    var screenX = Math.round((c.x + 0.5) * Terrain.spriteW) - viewX - 61;
    var screenY = c.y * Terrain.spriteH - viewY - 52 - 30;
    selectionDiv.style.left = screenX + "px";
    selectionDiv.style.top = screenY + "px";
    
    sel_name.innerHTML = Type.getClassName(Type.getClass(selection));
    sel_level.innerHTML = "Level " + selection.level;
  }
  
  /// If selection was null, fades in the selection box
  /// Sets selection to sel
  /// Makes world dirty
  function select(sel : Ent)
  {
    if (selection == null) {
      selectionDiv.style.display = "block";
      
      (cast js.Lib.window).setTimeout(function() {
        if (selection != null) {
          selectionDiv.style.opacity = 1;
        }
      }, 100);
    }
    
    selection = sel;
    world.makeDirty();
  }
  
  /// Assuming selection is not null:
  /// Sets selection to null
  /// Fades out the selection box
  /// Make world dirty
  function deselect()
  {
    selection = null;
    selectionDiv.style.opacity = 0;
    world.makeDirty();
    
    (cast js.Lib.window).setTimeout(function() {
      if (selection == null) selectionDiv.style.display = "none";
    }, 500);
  }

  public function doneLoading()
  {
    dia_loading.hide();
    dia_instructions.show();
  }

  static inline function randFor(x : Int, y : Int) : Rand
  {
    var rand = new Rand(x * 3846 + y * 9237);
    rand.next();
    return rand;
  }
  
  /// Constructs and appends (at the end) a banner indicating that the player has
  /// advanced to the given level.  Schedules said banner for removal
  public function levelUpBanner(level : Int)
  {
    var div = js.Lib.document.createElement("div");
    div.className = "achv";
    
    var img = js.Lib.document.createElement("img");
    (cast img).src = "level up.png";
    img.className = "lev_img";
    div.appendChild(img);
    
    var type = js.Lib.document.createElement("div");
    type.className = "type";
    type.innerHTML = "LEVEL-UP";
    div.appendChild(type);
    
    var levelup = js.Lib.document.createElement("div");
    levelup.className = "levelup";
    levelup.innerHTML = "Level " + level;
    div.appendChild(levelup);
    
    achievements.appendChild(div);
    scheduleBanner(div);
  }
  
  /// Starts the necessary timers to fade away, shrink, then delete the
  /// given banner after 5 seconds
  /// The given element should be the outermost div of the banner
  public function scheduleBanner(el : Dynamic)
  {
    (cast js.Lib.window).setTimeout(function() {
      el.style.opacity = 0;
      (cast js.Lib.window).setTimeout(function() {
        el.style.height = 0;
        el.style.marginBottom = 0;
        el.style.borderWidth = 0;
        (cast js.Lib.window).setTimeout(function() {
          el.parentNode.removeChild(el);
        }, 1000);
      }, 1000);
    }, 5000);
  }
}

enum Dir
{
  up;
  right;
  down;
  left;
}
