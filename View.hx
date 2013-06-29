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
  var sel_hp : Dynamic;
  var edit_name_btn : Dynamic;
  var edit_name_in : Dynamic;
  public var ul_achv : Dynamic;
  
  var el_howto_wrap : Dynamic;
  var el_howto : Dynamic;
  var el_howto_title : Dynamic;
  var el_howto_prev : Dynamic;
  var el_howto_next : Dynamic;
  var el_howto_close : Dynamic;
  
  var curr_lev : Dynamic;
  var next_lev : Dynamic;
  var lev_bar : Dynamic;
  var health : Dynamic;

  public var viewX : Int = 0;
  public var viewY : Int = 0;

  var viewW : Int = -1;
  var viewH : Int = -1;
  
  var selection : Ent = null;
  var nameSelection : Ent.Nameable;

  var factory : World.Factory;
  public var world : World;

  var prevTime : Float;

  public var binder : KeyBinder;

  // dialogs:
  var dia_instructions : Dia;
  var dia_win : Dia;
  var dia_lose : Dia;
  var dia_loading : Dia;
  var dia_seed : Dia;
  var dia_change_seed : Dia;
  public var dia_achievements : Dia;
  var dia_about : Dia;
  var dia_edit_name : Dia;
  
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
  
  // how-to:
  var howto : HowTo;
  var howtoIndex : Int;
  var howtoSection : Dynamic;
  
  public var btn_dismount : Dynamic;

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
    sel_hp = js.Lib.document.getElementById("sel_hp");
    edit_name_btn = js.Lib.document.getElementById("edit_name_btn");
    edit_name_in = js.Lib.document.getElementById("edit_name_in");
    ul_achv = js.Lib.document.getElementById("ul_achv");
    
    el_howto_wrap = js.Lib.document.getElementById("howto_wrap");
    el_howto = js.Lib.document.getElementById("howto");
    el_howto_title = js.Lib.document.getElementById("howto_title");
    el_howto_prev = js.Lib.document.getElementById("howto_prev");
    el_howto_prev.onclick = howToPrev;
    el_howto_next = js.Lib.document.getElementById("howto_next");
    el_howto_next.onclick = howToNext;
    el_howto_close = js.Lib.document.getElementById("howto_close");
    el_howto_close.onclick = howToClose;
  
    curr_lev = js.Lib.document.getElementById("curr");
    next_lev = js.Lib.document.getElementById("next");
    lev_bar = js.Lib.document.getElementById("bar");
    health = js.Lib.document.getElementById("health");

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

    dia_win = new Dia("dia_win");
    dia_win.bind({ close: dia_win.hide, restart: restartGame });
    dia_lose = new Dia("dia_lose");
    dia_lose.bind({ restart: restartGame });
    dia_instructions = new Dia("dia_instructions");
    dia_instructions.bind({ close: dia_instructions.hide });
    
    var inst_topics = js.Lib.document.getElementById("inst_topics");
    new JQuery(js.Lib.document.body).children(".howto").each(function(i, el) {
      var ht = new HowTo(el);
    
      var li = js.Lib.document.createElement("li");
      var a = js.Lib.document.createElement("a");
      a.onclick = cast function() {
        howto = ht;
        howtoIndex = 0;
        dia_instructions.hide();
        updateHowTo();
      };
      a.innerHTML = ht.title;
      
      li.appendChild(a);
      inst_topics.appendChild(li);
    });
    
    dia_loading = new Dia("dia_loading", true);
    dia_seed = new Dia("dia_seed");
    dia_seed.bind({ close: dia_seed.hide, change: function() { dia_seed.hide(); dia_change_seed.show(); } });
    dia_change_seed = new Dia("dia_change_seed");
    dia_change_seed.bind({ cancel: dia_change_seed.hide, accept: readSeed });
    dia_achievements = new Dia("dia_achievements");
    dia_achievements.bind({ close: dia_achievements.hide });
    dia_about = new Dia("dia_about");
    dia_about.bind({ close: dia_about.hide });
    dia_edit_name = new Dia("dia_edit_name");
    dia_edit_name.bind({ accept: acceptName, cancel: dia_edit_name.hide });
    
    edit_name_btn.onclick = editName;

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
    binder.bind(191, dia_instructions.show); // '?'
    binder.bind(65, dia_achievements.show); // 'a'
    //~ binder.bind(69, function() { // 'e'
    //~ });
    
    //~ binder.uncaught(function(k) throw "Key: " + k);

    var c = new JQuery(canvas);
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
    Ent.Player.p.reset();
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
      case Hp(s):
        li.className = "hp";
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
  
  /// Constructs and displays a bubble horizontally and vertically centered on Ent
  /// Adds the bubble to the registry
  /// Animates the bubble to float up and fade away
  /// Schedules the deletion of the bubble once faded
  public function emitBubble(img : Dynamic, ent : Ent)
  {
    new Bubble(img, ent);
  }

  public function draw()
  {
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
              }

              context.globalAlpha = 1;

              if (hasEnt) {
                if (selection == ent) {
                  var selImg = Images.i.selection;
                  context.drawImage(selImg, lx - Math.round(selImg.width / 2), ly - Math.round(selImg.height / 2));
                } else if ((cast ent).name != null) {
                  var namImg = Images.i.named;
                  context.drawImage(namImg, lx - Math.round(namImg.width / 2), ly - Math.round(namImg.height / 2));
                }
              
                if (!ent.alive) context.globalAlpha = 0.75;
                var img = ent.sprite;
                context.drawImage(img, lx - Math.floor(img.width / 2), ly - img.height);
                if (!ent.alive) {
                  context.globalAlpha = 1;
                  context.drawImage(skull, lx - skullW, ly - skullH);
                } else if (ent.hp != ent.maxHp) {
                  var dotX = x * Terrain.spriteW - offX;
                  var dotY = (y + 1) * Terrain.spriteH - offY - 14;
                  for (i in 0...ent.maxHp) {
                    var img = if (i < ent.hp) Images.i.hpDot else Images.i.emptyHpDot;
                    context.drawImage(img, dotX, dotY);
                    dotX += 10;
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  function animate() {
    if (resized) resize();
    lookAt(Ent.Player.p.coord);
    if (selection != null) updateSelection();
    draw();
    updateCompass();
    updateStats();
    Bubble.updateAll();
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
    
    if (Std.is(selection, Ent.Nameable)) {
      var name = (cast selection).name;
      sel_name.innerHTML = if (name != null) '"' + name + '"' else selection.getName();
      edit_name_btn.style.display = "inline";
    } else {
      sel_name.innerHTML = selection.getName();
      edit_name_btn.style.display = "none";
    }
    
    sel_level.innerHTML = "Level " + selection.level;
    
    sel_hp.innerHTML = "";
    for (i in 0...selection.maxHp) {
      var img = js.Lib.document.createElement("img");
      (cast img).src = if (i < selection.hp) Images.i.hp.src else Images.i.emptyHp.src;
      sel_hp.appendChild(img);
    }
    
    var screenX = Math.round((c.x + 0.5) * Terrain.spriteW) - viewX;
    var screenY = c.y * Terrain.spriteH - viewY - 25;
    
    var jq = new JQuery(selectionDiv);
    var halfWidth = Math.round(jq.width() / 2) + 15;
    
    selectionDiv.style.left = screenX - halfWidth + "px";
    selectionDiv.style.bottom = viewH - screenY + "px";
  }
  
  /// Updates the XP and health bar with the player's current stats
  function updateStats()
  {
    var p = Ent.Player.p;
    
    curr_lev.innerHTML = p.level;
    next_lev.innerHTML = p.level + 1;
    lev_bar.style.width = p.xpProgress() * 100 + "%";
    
    health.innerHTML = "";
    
    for (i in 0...p.maxHp) {
      var img = js.Lib.document.createElement("img");
      (cast img).src = if (i < p.hp) Images.i.heart.src else Images.i.emptyHeart.src;
      health.appendChild(img);
    }
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
  
  /// Sets the name of selection to what the user entered in the input box
  /// of the "Edit Name" dialog
  /// WS is trimmed
  /// If the entry (after trimming) is empty, the name is set to null
  /// Then the "Edit Name" dialog is hidden and the world is made dirty
  function acceptName()
  {
    var name : String = edit_name_in.value.trim();
    if (name.length == 0) name = null;
    nameSelection.name = name;
    
    dia_edit_name.hide();
    world.makeDirty();
  }
  
  /// Prepares and displays the "Edit Name" dialog box for selection
  /// Sets the value of the name input to selection's current name
  /// Sets nameSelection to selection (in case the user changes selection
  /// before closing the dialog)
  /// Then shows the dialog
  function editName()
  {
    var name = (cast selection).name;
    if (name == null) name = "";
    edit_name_in.value = name;
    
    nameSelection = cast selection;
    
    dia_edit_name.show();
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
    type.innerHTML = "Level-Up";
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
  
  /// Updates the how-to-play display for the current values of howto and
  /// howtoIndex
  /// Updates howtoSection appropriately
  /// If howto is null, the how-to-play box (if showing) will fade out, otherwise:
  /// If another section is currently displayed, it will fade out
  /// The new section will fade in
  /// The title will be updated
  /// The prev and next buttons will be updated
  function updateHowTo()
  {
    if (howto == null) {
      el_howto.style.opacity = el_howto_prev.style.opacity = el_howto_next.style.opacity = 0;
      
      var hsect = howtoSection;
      howtoSection = null;
      
      (cast js.Lib.window).setTimeout(function() {
        if (howtoSection == null) { // if nothing else has happened since setTimeout
          el_howto_title.innerHTML = "";
          if (hsect != null) {
            el_howto.removeChild(hsect);
          }
          el_howto_wrap.style.display = "none";
        }
      }, 500);
    } else {
      el_howto_title.innerHTML = howto.title;
      el_howto_wrap.style.display = "block";
      
      var sect = howto.sections[howtoIndex];
      var hsect = howtoSection;
      (cast js.Lib.window).setTimeout(function() {
        el_howto.style.opacity = 1;
        
        el_howto_prev.style.opacity = if (howtoIndex > 0) 1 else 0;
        el_howto_next.style.opacity = if (howtoIndex < howto.sections.length - 1) 1 else 0;
        
        var show = function() {
          sect.style.opacity = 0;
          el_howto.appendChild(sect);
          (cast js.Lib.window).setTimeout(function() {
            sect.style.opacity = 1;
          }, 100);
        };
        
        if (hsect != null) {
          hsect.style.opacity = 0;
          (cast js.Lib.window).setTimeout(function() {
            el_howto.removeChild(hsect);
            show();
          }, 500);
        } else {
          show();
        }
      }, 100);
      howtoSection = sect;
    }
  }
  
  /// Advances to the next section of the current how-to
  /// Does not do anything when howtoIndex is already at the end of the array
  /// Calls updateHowTo() when howtoIndex is changed
  function howToNext()
  {
    if (howtoIndex < howto.sections.length - 1) {
      ++howtoIndex;
      updateHowTo();
    }
  }
  
  /// Returns to the previous section of the current how-to
  /// Does not do anything when howtoIndex is already at 0
  /// Calls updateHowTo() when howtoIndex is changed
  function howToPrev()
  {
    if (howtoIndex > 0) {
      --howtoIndex;
      updateHowTo();
    }
  }
  
  /// Sets howto to null then calls updateHowTo()
  function howToClose()
  {
    howto = null;
    updateHowTo();
  }
}

class Bubble
{
  static var registry : Array<Bubble> = new Array();

  var img : Dynamic;
  var ent : Ent;
  
  var wrap : Dynamic;
  var inner : Dynamic;
  
  public function new(img, ent)
  {
    this.img = img;
    this.ent = ent;
    
    wrap = js.Lib.document.createElement("div");
    inner = js.Lib.document.createElement("img");
    inner.src = img.src;
    wrap.appendChild(inner);
    
    wrap.className = "bubble";
    update();
    
    js.Lib.document.body.appendChild(wrap);
    
    registry.push(this);
    
    (cast js.Lib.window).setTimeout(function() {
      wrap.className = "bubble bubbleUp";
      
      (cast js.Lib.window).setTimeout(remove, 1000);
    }, 200);
  }
  
  /// Removes this from registry and removes wrap from the document
  function remove()
  {
    registry.remove(this);
    js.Lib.document.body.removeChild(wrap);
  }
  
  /// Moves this bubble so it is over x and y in the view
  function update()
  {
    if (ent.coord == null || ent.coord.distanceTo(Ent.Player.p.coord) > View.ViewDist) {
      remove();
    } else {
      var vx = ent.coord.x * Terrain.spriteW - View.v.viewX + Math.floor(Terrain.spriteW / 2 - img.width / 2);
      var vy = ent.coord.y * Terrain.spriteH - View.v.viewY - img.height - 20;
      
      wrap.style.left = vx;
      wrap.style.top = vy;
    }
  }
  
  /// Goes through registry and updates each bubble
  public static function updateAll()
  {
    for (b in registry) b.update();
  }
}

class HowTo
{
  public var title : String;
  public var sections : Array<Dynamic>;
  
  public function new(howto : Dynamic)
  {
    var jq = new JQuery(howto);
    title = jq.children("h1").html();
    
    sections = new Array();
    jq.children("section").each(function(i, s) sections.push(s));
  }
}

enum Dir
{
  up;
  right;
  down;
  left;
}
