class Utils
{
  public static inline function map<T, U>(iter : Iterator<T>, f : T -> U) : Iterator<U>
  {
    return {
      next: function() return f(iter.next()),
      hasNext: iter.hasNext
    };
  }

  public static inline function flatten<T>(iter : Iterator<T>) : Array<T>
  {
    var arr = new Array<T>();
    for (a in iter) {
      arr.push(a);
    }
    return arr;
  }

  public static inline function clamp(a : Int, min : Int, max : Int) : Int
  {
    return
      if (a < min) min
      else if (a > max) max
      else a;
  }

  public static inline function sign(a : Int) : Int
  {
    return if (a < 0) -1 else 1;
  }

  public static inline function wrap<T>(grid : Array<Array<T>>, x : Int, y : Int) : T
  {
    var width = grid[0].length;
    while (x < 0) x += width;
    while (x >= width) x -= width;

    var height = grid.length;
    while (y < 0) y += height;
    while (y >= height) y -= height;

    return grid[y][x];
  }

  public static inline function wrapTo<T>(coord : World.Coord, grid : Array<Array<T>>)
  {
    var width = grid[0].length;
    while (coord.x < 0) coord.x += width;
    while (coord.x >= width) coord.x -= width;

    var height = grid.length;
    while (coord.y < 0) coord.y += height;
    while (coord.y >= height) coord.y -= height;
  }

  public static inline function equals(a : World.Coord, b : World.Coord) : Bool
  {
    return if (a == null || b == null) a == b
           else a == b || (a.x == b.x && a.y == b.y);
  }
  
  public static inline function add(a : World.Coord, b : World.Coord) : World.Coord
  {
    return { x: a.x + b.x, y: a.y + b.y };
  }

  public static function distanceTo(a : World.Coord, b : World.Coord) : Float
  {
    return Math.sqrt(Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2));
  }

  public static function directionTo(a : World.Coord, b : World.Coord) : World.Coord
  {
    var angle = Math.round(Math.atan((a.y - b.y) / (b.x - a.x)) / Math.PI * 4);
    var dir = { x: switch (angle) {
                     case -2, 2: 0;
                     case -1, 0, 1: 1;
                   },
                y: switch (angle) {
                     case 1, 2: -1;
                     case 0: 0;
                     case -2, -1: 1;
                   }
              };
    if (b.x - a.x < 0) {
      dir.x *= -1;
      dir.y *= -1;
    }
    return dir;
  }

  public static inline function getNeighbors(c : World.Coord) : Array<World.Coord>
  {
    return [{ x: c.x - 1, y: c.y - 1 },
            { x: c.x    , y: c.y - 1 },
            { x: c.x + 1, y: c.y - 1 },
            { x: c.x + 1, y: c.y     },
            { x: c.x + 1, y: c.y + 1 },
            { x: c.x    , y: c.y + 1 },
            { x: c.x - 1, y: c.y + 1 },
            { x: c.x - 1, y: c.y     }];
  }

  /// Returns all coordinates within center.x - r, center.x + r inclusive
  /// and center.y - r, center.y + r inclusive
  /// Note this is actually a square, not a circle
  public static function getRadius(center : World.Coord, r : Int) : Array<World.Coord>
  {
    var arr = new Array<World.Coord>();
    for (xd in -r...r) {
      for (yd in -r...r) {
        var c = { x: center.x + xd, y: center.y + yd };
        arr.push(c);
      }
    }
    return arr;
  }
}
