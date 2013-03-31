using Utils;

class View
{
  var canvas : Dynamic;
  var context : Dynamic;
  var gridPos : Dynamic;
  var stats : Dynamic;

  var viewX : Int = 0;
  var viewY : Int = 0;

  var viewW : Int;
  var viewH : Int;

  var factory : World.Factory;
  var world : World;

  var prevTime : Float;

  var dragStart : { x : Int, y : Int } = null;
  var mousePos : { x : Int, y : Int };
  var arrowKey : Null<Dir> = null;

  var animateRunning = false;

  var showElevation : Bool = false;
  var showGrid : Bool = false;

  // stats:
  var s_tiles : Int;
  var s_sprites : Int;
  var s_overlays : Int;

  public function new(canvasId : String)
  {
    factory = new World.Factory();

    var grass = ImgLoader.get("grass.png");
    var rock_spr = ImgLoader.get("rock sprite.png");
    var grass_spr = ImgLoader.get("grass tuft.png");
    var marker = ImgLoader.get("marker.png");

    var forest = new Terrain("Forest", grass, [{ sprite: ImgLoader.get("tree.png"), prob: 0.8 }]);
    var grass = new Terrain("Grass", grass, [{ sprite: rock_spr, prob: 0.05 }, { sprite: grass_spr, prob: 0.8 }]);
    var water = new Terrain("Water", ImgLoader.get("water.png"), []);
    var rock = new Terrain("Rock", ImgLoader.get("rock.png"), [{ sprite: rock_spr, prob: 0.5 }]);

    factory.addTerrain(forest);
    factory.addTerrain(grass);
    factory.addTerrain(rock, 0.2);
    factory.addTerrain(water, 4);

    genWorld(652);//Std.random(999));

    world.addOverlay({ sprite: marker, coord: { x: 10, y: 20 } });

    canvas = js.Lib.document.getElementById(canvasId);
    gridPos = js.Lib.document.getElementById("grid_pos");
    stats = js.Lib.document.getElementById("stats");

    canvas.width = (cast js.Lib.window).innerWidth;
    canvas.height = (cast js.Lib.window).innerHeight;

    context = canvas.getContext("2d");

    viewW = canvas.width;
    viewH = canvas.height;

    mousePos = { x: 0, y: 0 };

    canvas.addEventListener("mousedown", function(ev) {
      dragStart = { x: ev.clientX, y: ev.clientY };

    });

    var mouseup = function(ev) {
      dragStart = null;
    };
    canvas.addEventListener("mouseup", mouseup);
    canvas.addEventListener("mouseleave", mouseup);

    (cast js.Lib.window).addEventListener("mousemove", function(ev) {
      mousePos.x = ev.clientX;
      mousePos.y = ev.clientY;

      var gridX = Math.floor((mousePos.x + viewX) / Terrain.spriteW);
      var gridY = Math.floor((mousePos.y + viewY) / Terrain.spriteH);

      gridPos.innerHTML = "(" + gridX + ", " + gridY + ")";

      if (!animateRunning) animate(-1);
    });

    canvas.addEventListener("keypress", function(ev) {
      var c : Int = ev.charCode;
      switch (c) {
        case 104: // 'h'
          showElevation = !showElevation;
          draw();
        case 103: // 'g'
          showGrid = !showGrid;
          draw();
        case 56: // '8'
          var ov = arrowKey;
          arrowKey = Dir.up;
          if (!animateRunning) animate(-1);
        case 54: // '6'
          var ov = arrowKey;
          arrowKey = Dir.right;
          if (!animateRunning) animate(-1);
        case 50: // '2'
          var ov = arrowKey;
          arrowKey = Dir.down;
          if (!animateRunning) animate(-1);
        case 52: // '4'
          var ov = arrowKey;
          arrowKey = Dir.left;
          if (!animateRunning) animate(-1);
        case 53: // '5'
          arrowKey = null;
        default:
          trace("Key press: " + c);
      }
    });

    var seedI = new Input<Int>("Seed", world.originalSeed, Std.parseInt);
    seedI.onChange = function(v) {
      genWorld(v);
      draw();
    };

    //~ var path = world.path({ x: 10, y: 2 }, { x: 40, y: 20 }, function(tile) return tile.type == water);
    //~ for (c in path) {
      //~ world.addOverlay({ sprite: marker, coord: c });
    //~ }
  }

  public static function main()
  {
    var v = new View("canv");
    v.draw();
  }

  function genWorld(seed)
  {
    world = factory.generate(seed);
  }

  public function draw()
  {
    s_tiles = s_sprites = s_overlays = 0;

    var grid = world.iterGrid().map(Utils.flatten).flatten();

    context.clearRect(0, 0, viewW, viewH);

    var startX = Math.floor(viewX / Terrain.spriteW);
    var startY = Math.floor(viewY / Terrain.spriteH);
    var offX = viewX - startX * Terrain.spriteW;// % Terrain.spriteW;
    var offY = viewY - startY * Terrain.spriteH;// % Terrain.spriteH;

    var vWidth = Math.ceil(viewW / Terrain.spriteW) + 1;
    var vHeight = Math.ceil(viewH / Terrain.spriteH) + 1;

    var endX = startX + vWidth;
    var endY = startY + vHeight;

    var rowLen = grid[0].length;

    // Draw base tiles
    for (y in 0...vHeight) {
      var ay = startY + y;
      if (ay < 0 || ay >= grid.length) {
      } else {
        var r = grid[ay];
        for (x in 0...vWidth) {
          var ax = startX + x;
          if (ax >= 0 && ax < rowLen) {
            var tile = r[ax];
            var lx = x * Terrain.spriteW - offX;
            var ly = y * Terrain.spriteH - offY;
            if (showElevation) {
              var e = Math.round(tile.elevation * 255 / 100);
              context.fillStyle = "rgb(" + e + "," + e + "," + e + ")";
              context.fillRect(lx, ly, Terrain.spriteW, Terrain.spriteH);
            } else {
              context.drawImage(tile.type.tile, lx, ly);
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

    // Draw sprites
    for (y in 0...vHeight) {
      var ay = startY + y;
      if (ay >= 0 && ay < grid.length) {
        var r = grid[ay];
        for (x in 0...vWidth) {
          var ax = startX + x;
          if (ax >= 0 && ax < rowLen) {
            var spr = r[ax].type.getSprite(randFor(ax, ay));

            var lx = x * Terrain.spriteW - offX + Math.floor(Terrain.spriteW / 2);
            var ly = y * Terrain.spriteH - offY + Math.floor(Terrain.spriteH / 2);

            var sprite = spr.sprite;
            if (sprite != null) {
              context.drawImage(sprite, lx + Math.floor(spr.x - sprite.width / 2), ly + Math.floor(spr.y - sprite.height));
              ++s_sprites;
            }

            //~ var overlays = world.overlaysAt(ax, ay);
            //~ for (o in overlays) {
              //~ var spr = o.sprite;
              //~ context.drawImage(spr, lx - Math.floor(spr.width / 2), ly - spr.height);
            //~ }
          }
        }
      }
    }

    // Draw overlays
    for (o in world.iterOverlays()) {
      var x = o.coord.x;
      var y = o.coord.y;

      if (x >= startX && x < endX && y >= startY && y < endY) {
        var spr = o.sprite;

        var lx : Int = Math.floor((x - startX) * Terrain.spriteW - offX + Terrain.spriteW / 2 - spr.width / 2);
        var ly : Int = Math.floor((y - startY) * Terrain.spriteH - offY + Terrain.spriteH - spr.height);

        context.drawImage(spr, lx, ly);
        ++s_overlays;
      }
    }

    showStats();
  }

  function showStats()
  {
    stats.innerHTML = "T: " + s_tiles + ", S: " + s_sprites + ", O: " + s_overlays;
  }

  function animate(time : Float) {
    animateRunning = true;

    var elap : Float = 0;
    if (time != -1) {
      elap = time - prevTime;
      prevTime = time;
    } else {
      prevTime = untyped __js__('Date.now()');
    }

    var keep = false;

    if (dragStart != null) {
      viewX -= mousePos.x - dragStart.x;
      viewY -= mousePos.y - dragStart.y;
      dragStart.x = mousePos.x;
      dragStart.y = mousePos.y;
      keep = true;
    }

    if (arrowKey != null) {
      var dist = Math.round(elap / 4);
      switch (arrowKey) {
        case Dir.up:
          viewY -= dist;
        case Dir.right:
          viewX += dist;
        case Dir.down:
          viewY += dist;
        case Dir.left:
          viewX -= dist;
      }
      keep = true;
    }

    if (keep) {
      draw();
      var f = animate;
      untyped __js__("window.mozRequestAnimationFrame(f)");
    } else {
      animateRunning = false;
    }
  }

  static inline function randFor(x : Int, y : Int) : Rand
  {
    var rand = new Rand(x * 3846 + y * 9237);
    rand.next();
    return rand;
  }
}

enum Dir
{
  up;
  right;
  down;
  left;
}
