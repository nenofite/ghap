using Utils;

class World
{
  var mix : Array<{ type : Terrain, prob : Float }>;

  var grid : Array<Array<Tile>>;
  var overlays : Array<Overlay>;

  var rand : Rand;
  public var originalSeed(default, null) : Int;

  var totalProb : Float;

  public function new(mix, totalProb, seed)
  {
    originalSeed = seed;
    rand = new Rand(seed);
    rand.next();

    this.mix = mix;
    this.totalProb = totalProb;
    grid = new Array();
    overlays = new Array();

    generate(15, 15);
    for (i in 0...4) subdivide();
  }

  function generate(w : Int, h : Int)
  {
    for (y in 0...h) {
      var row = new Array<Tile>();
      grid.push(row);
      for (x in 0...w) {
        var t = new Tile(genTerr(), Math.round(rand.next() * Tile.elevMax));
        row.push(t);
      }
    }
  }

  function subdivide()
  {
    var newGrid = new Array<Array<Tile>>();
    for (row in grid) {
      var newRow = new Array<Tile>();
      for (t in row) {
        newRow.push(t);
        newRow.push(t);
      }
      newGrid.push(newRow);
      newGrid.push(newRow);
    }

    grid = newGrid;

    // fill in diamond centers
    // X 0 X    X 0 X
    // 0 0 0 -> 0 X 0
    // X 0 X    X 0 X
    var y : Int = 1;
    while (y < grid.length) {
      var x : Int = 1;
      while (x < grid[0].length) {
        grid[y][x] = Tile.seed(rand,
                               grid.wrap(x - 1, y - 1),
                               grid.wrap(x + 1, y - 1),
                               grid.wrap(x - 1, y + 1),
                               grid.wrap(x + 1, y + 1));
        x += 2;
      }
      y += 2;
    }

    // fill in square sides
    // X 0 X    X X X
    // 0 X 0 -> X X X
    // X 0 X    X X X
    y = 0;
    while (y < grid.length) {
      var x = if (y % 2 == 0) 1 else 0;
      while (x < grid[0].length) {
        grid[y][x] = Tile.seed(rand,
                               grid.wrap(x, y - 1),
                               grid.wrap(x + 1, y),
                               grid.wrap(x, y + 1),
                               grid.wrap(x - 1, y));

        x += 2;
      }
      y++;
    }
  }

  public function addOverlay(o : Overlay)
  {
    overlays.push(o);
  }

  public function overlaysAt(x : Int, y : Int) : Array<Overlay>
  {
    var arr = new Array<Overlay>();
    for (o in overlays) {
      var c = o.coord;
      if (c.x == x && c.y == y) arr.push(o);
    }
    return arr;
  }

  public inline function iterOverlays() : Iterator<Overlay>
  {
    return overlays.iterator();
  }

  public function iterGrid() : Iterator<Iterator<Tile>>
  {
    return grid.iterator().map(function(r) return r.iterator());
  }

  public function addTerrain(type : Terrain, prob : Float = 1)
  {
    totalProb += prob;
    mix.push({ type: type, prob: prob });
  }

  function genTerr() : Terrain
  {
    //~ var w = Math.random() * totalProb;
    var w = rand.next() * totalProb;
    for (i in 0...mix.length) {
      w -= mix[i].prob;
      if (w <= 0) return mix[i].type;
    }
    // shouldn't really ever reach this:
    throw "How did I get here?";
    return mix[mix.length - 1].type;
  }

  inline function heuristic(from : Coord, to : Coord) : Float
  {
    return Math.sqrt(Math.pow(from.x - to.x, 2) + Math.pow(from.y - to.y, 2));
  }

  inline function key(c : Coord) : String
  {
    return c.x + "_" + c.y;
  }

  public function path(start : Coord, dest : Coord, traversible : Tile -> Bool) : Path
  {
    var open = new Heap<PTile>(function(a, b) return (b.g + b.f) - (a.g + a.f));
    var openpt : PTile = { coord: start, parent: null, f: heuristic(start, dest), g: 0 };
    open.add(openpt);
    var onOpen = new Map<PTile>();
    onOpen.set(key(start), openpt);

    var closed = new Map<PTile>();

    var path : PTile = null;
    var t : PTile;

    while (path == null && (t = open.pop()) != null) {
      closed.set(key(t.coord), t);
      //onOpen.set(key(t.coord), null);

      for (delta in [{ x: 0, y: -1 },
                     { x: 1, y: 0 },
                     { x: 0, y: 1 },
                     { x: -1, y: 0 }]) {
        delta.x += t.coord.x;
        delta.y += t.coord.y;
        delta.wrapTo(grid);

        if (delta.equals(dest)) {
          path = t;
          break;
        }

        var k = key(delta);
        if (traversible(grid[delta.y][delta.x]) && closed.get(k) == null) {
          var pt : PTile = { coord: delta, parent: t, f: heuristic(delta, dest), g: 1 + t.g };

          var onOp = onOpen.get(k);
          if (onOp == null) {
            open.add(pt);
            onOpen.set(k, pt);
          } else {
            if (onOp.g > pt.g) {
              open.remove(onOp);
              open.add(pt);
              onOpen.set(k, pt);
            }
          }
        }
      }
    }

    if (path == null) return null;

    var fullPath : Path = [dest, path.coord];
    while ((path = path.parent) != null) fullPath.push(path.coord);
    return fullPath;
  }

  //~ public inline function path(start : Coord, dest : Coord, traversible : Tile -> Bool) : Path
  //~ {
    //~ return _path(start, dest, traversible).path;
  //~ }
//~
  //~ function _path(start : Coord, dest : Coord, traversible : Tile -> Bool) : { path : Path, cost : Float }
  //~ {
    //~ if (start.equals(dest)) {
      //~ trace("Hit at " + start);
      //~ return { path: [dest], cost: 0 };
    //~ }
//~
    //~ var options = new Array<{ coord : Coord, heur : Int }>();
//~
    //~ for (c in [{ x: 0, y: -1 },
               //~ { x: 1, y: 0 },
               //~ { x: 0, y: 1 },
               //~ { x: -1, y: 0 }]) {
      //~ c.x += start.x;
      //~ c.y += start.y;
      //~ c.wrapTo(grid);
      //~ if (traversible(grid[c.y][c.x])) {
        //~ options.push({ coord: c, heur: heuristic(c, dest) });
      //~ }
    //~ }
//~
    //~ options.sort(function(a, b) return a.heur - b.heur);
//~
    //~ trace("At " + start);
    //~ for (opt in options) {
      //~ trace("Trying " + opt.coord);
      //~ var subpath = _path(opt.coord, dest, traversible);
      //~ if (subpath != null) {
        //~ subpath.path.push(start);
        //~ ++subpath.cost;
        //~ return subpath;
      //~ }
    //~ }
    //~ return null;
  //~ }
}

private typedef PTile = { coord : Coord, parent : PTile, f : Float, g : Float };

class Factory
{
  var mix : Array<{ type : Terrain, prob : Float }>;
  var totalProb : Float = 0;

  public function new()
  {
    mix = new Array();
  }

  public function addTerrain(type : Terrain, prob : Float = 1)
  {
    totalProb += prob;
    mix.push({ type: type, prob: prob });
  }

  public function generate(seed : Int) : World
  {
    return new World(mix, totalProb, seed);
  }
}

class Tile
{
  public static inline var elevMax = 100;
  static inline var elevVariance = 5;

  public var type(default, null) : Terrain;
  public var elevation(default, null) : Int;

  public function new(type, elevation)
  {
    this.type = type;
    this.elevation = elevation;
  }

  public static function seed(rand : Rand, a : Tile, b : Tile, c : Tile, d : Tile) : Tile
  {
    var elev : Int = Math.round((a.elevation + b.elevation + c.elevation + d.elevation) / 4);
    elev += Math.round(rand.next() * elevVariance);

    var index : Int = Math.floor(rand.next() * 4);
    var type = (switch (index) {
      case 0: a;
      case 1: b;
      case 2: c;
      case 3: d;
    }).type;

    return new Tile(type, elev);
  }
}

typedef Path = Array<Coord>;

typedef Overlay = { sprite : Dynamic, coord : Coord };

typedef Coord = { x : Int, y : Int };
