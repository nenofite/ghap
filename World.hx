using Utils;

class World
{
  public static inline var UpdateDist = 12;

  var mix : Array<TerrainSpec>;

  // row-major
  var grid : Array<Array<Tile>>;
  public var ents : Hash<Ent>;

  var rand : Rand;
  public var originalSeed(default, null) : Int;

  var totalProb : Float;

  public var dirty(default, null) : Bool;
  public var onDirty : Void -> Void = null;

  public var clearLog : Void -> Void = null;
  public var log : Log -> Void = null;

  public var win : Void -> Void = null;
  public var lose : Void -> Void = null;

  public function new(mix, totalProb, entMix : Array<EntSpec>, seed)
  {
    originalSeed = seed;
    rand = new Rand(seed);
    rand.next();

    this.mix = mix;
    this.totalProb = totalProb;
    grid = new Array();
    ents = new Hash();

    generate(15, 15);
    for (i in 0...4) subdivide();

    for (em in entMix) {
      for (i in 0...em.num) {
        while (true) {
          var c = { x: Math.floor(rand.next() * grid[0].length),
                    y: Math.floor(rand.next() * grid.length) };

          if (inBounds(c) && em.matches(c, this)) {
            addEnt(c, em.make(rand));
            break;
          }
        }
      }
    }

    dirty = false;
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

  public inline function tileAt(c : Coord) : Tile
  {
    if (!inBounds(c)) throw "Out of bounds: " + c;
    return grid[c.y][c.x];
  }

  public inline function inBounds(c : Coord) : Bool
  {
    return c.x >= 0 && c.y >= 0 && c.x < grid[0].length && c.y < grid.length;
  }

  public function addEnt(c : Coord, e : Ent)
  {
    if (e == null) throw "Called addEnt() with null Ent.";
    if (e.coord != null) throw "Called addEnt() with already located Ent.";
    if (!inBounds(c)) throw "Coord out of bounds: " + c;

    ents.set(key(c), e);
    e.coord = c;
    makeDirty();
  }

  public function removeEnt(c : Coord) : Null<Ent>
  {
    var k = key(c);
    var old = ents.get(k);
    if (old != null) {
      ents.remove(k);
      old.coord = null;
    }
    return old;
  }

  public function moveEnt(from : Coord, to : Coord) : Null<Ent>
  {
    var e = ents.get(key(from));
    var old = null;
    if (e != null) {
      old = removeEnt(to);
      removeEnt(from);
      addEnt(to, e);
    }
    return old;
  }

  public inline function entAt(c : Coord) : Ent
  {
    return ents.get(key(c));
  }

  public inline function entAt2(x : Int, y : Int) : Ent
  {
    return ents.get(key2(x, y));
  }

  public function updateEnts()
  {
    clearLog();
    Ent.walriFollowing = if (Ent.Player.p.onWalrus != null) 1 else 0;

    var coords = Ent.Player.p.coord.getRadius(UpdateDist);
    var updateEnts = new Array<Ent>();
    for (c in coords) {
      var e = ents.get(key(c));
      if (e != null && e.coord != null && e.alive) updateEnts.push(e);
    }
    
    for (e in updateEnts) {
      if (e.coord != null && e.alive) e.update(this);
    }
    
    if (Ent.walriFollowing >= 10) Achievement.aPopular.qualify();
    
    //~ for (c in coords) {
      //~ var e = ents.get(key(c));
      //~ if (e != null && e.coord != null && e.alive) e.update(this);
    //~ }
    makeDirty();
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
    return from.distanceTo(to);
    //~ return Math.sqrt(Math.pow(from.x - to.x, 2) + Math.pow(from.y - to.y, 2));
  }

  inline function key(c : Coord) : String
  {
    return key2(c.x, c.y);
  }

  inline function key2(x : Int, y : Int) : String
  {
    return x + "_" + y;
  }

  /// Use A* to calculate a path
  /// Can travel in all 8 directions
  /// Uses traversible to determine if a tile is available for the path
  /// If a path can be found:
  ///  Returned path starts with dest and ends with start (it's in reverse)
  /// If no path can be found:
  ///  Path starts with closest point possible, ends with start (in reverse)
  public function path(start : Coord, dest : Coord, traversible : Terrain -> Coord -> Bool) : Path
  {
    var open = new Heap<PTile>(function(a, b) return (b.g + b.f) - (a.g + a.f));
    var openpt : PTile = { coord: start, parent: null, f: heuristic(start, dest), g: 0 };
    open.add(openpt);
    var onOpen = new Map<PTile>();
    onOpen.set(key(start), openpt);

    var closed = new Map<PTile>();

    var path : PTile = null; // whichever touches the destination
    var best : PTile = openpt; // whichever gets closest to the destination (using heuristic)
    var t : PTile;

    while (path == null && (t = open.pop()) != null) {
      closed.set(key(t.coord), t);

      for (delta in t.coord.getNeighbors()) {
        if (!inBounds(delta)) continue;

        if (delta.equals(dest)) {
          path = t;
          break;
        }

        var k = key(delta);
        if (traversible(grid[delta.y][delta.x].type, delta) && closed.get(k) == null) {
          var pt : PTile = { coord: delta, parent: t, f: heuristic(delta, dest), g: 1 + t.g };

          if (pt.f < best.f) best = pt;

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

    var chosen : PTile;
    var fullPath : Path;
    
    if (path != null) {
      chosen = path;
      fullPath = [dest, path.coord];
    } else {
      chosen = best;
      fullPath = [best.coord];
    }
    
    while ((chosen = chosen.parent) != null) fullPath.push(chosen.coord);
    return fullPath;
  }

  public inline function makeDirty()
  {
    if (!dirty) {
      dirty = true;
      if (onDirty != null) onDirty();
    }
  }

  public inline function makeClean()
  {
    dirty = false;
  }
}

private typedef PTile = { coord : Coord, parent : PTile, f : Float, g : Float };

class Factory
{
  static inline var ZOMBIE_DIST = 20;
  static inline var PANDA_DIST = 80;
  static inline var PANDA_MOB_DIST1 = 8;
  static inline var PANDA_MOB_DIST2 = 16;
  static inline var WALRUS_DIST = 5;

  var mix : Array<TerrainSpec>;
  var totalProb : Float = 0;

  var entMix : Array<EntSpec>;

  public function new()
  {
    mix = new Array();
    entMix = new Array();
  }

  public static function makeDefault() : Factory
  {
    var f = new Factory();

    f.addTerrain(Terrain.forest);
    f.addTerrain(Terrain.grass);
    f.addTerrain(Terrain.rock, 0.2);
    f.addTerrain(Terrain.water, 4);

    f.addEnt(1, function(c, w) return Ent.isWalkTraversible(w.tileAt(c).type), function(r) return Ent.Player.p);
    f.addEnt(1, function(c, w) return Ent.isAmphTraversible(w.tileAt(c).type) && c.distanceTo(Ent.Player.p.coord) <= WALRUS_DIST, function(r) return new Ent.Walrus(1));
    f.addEnt(100, function(c, w) return Ent.isAmphTraversible(w.tileAt(c).type), function(r) return new Ent.Walrus(Math.floor(r.next() * 3) + 1));
    f.addEnt(100, function(c, w) return Ent.isWalkTraversible(w.tileAt(c).type) && c.distanceTo(Ent.Player.p.coord) >= ZOMBIE_DIST, function(r) return new Ent.Zombie(Math.floor(r.next() * 5) + 1));
    f.addEnt(1, function(c, w) return Ent.isWalkTraversible(w.tileAt(c).type) && c.distanceTo(Ent.Player.p.coord) >= PANDA_DIST, function(r) return new Ent.Panda());
    f.addEnt(15, function(c, w) return Ent.isWalkTraversible(w.tileAt(c).type) && c.distanceTo(Ent.panda.coord) <= PANDA_MOB_DIST1, function(r) return new Ent.Zombie(Math.floor(r.next() * 5) + 3));
    f.addEnt(30, function(c, w) return Ent.isWalkTraversible(w.tileAt(c).type) && c.distanceTo(Ent.panda.coord) <= PANDA_MOB_DIST2, function(r) return new Ent.Zombie(Math.floor(r.next() * 5) + 1));

    return f;
  }

  public function addTerrain(type : Terrain, prob : Float = 1)
  {
    totalProb += prob;
    mix.push({ type: type, prob: prob });
  }

  public function addEnt(num : Int, matches : Coord -> World -> Bool, make : Rand -> Ent)
  {
    entMix.push({ num: num, matches: matches, make: make });
  }

  public function generate(seed : Int) : World
  {
    return new World(mix, totalProb, entMix, seed);
  }
}

// TODO remove this class, only need Terrain
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

typedef TerrainSpec = { type : Terrain, prob : Float };
typedef EntSpec = { num : Int, matches : Coord -> World -> Bool, make : Rand -> Ent };

enum Log
{
  Error(msg : String);
  Battle(msg : String);
  Xp(msg : String);
}
