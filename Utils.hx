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
    return a.x == b.x && a.y == b.y;
  }

  //~ public static inline function addWrap<T>(coord : World.Coord, xd : Int, yd : Int, grid : Array<Array<T>>) : World.Coord
  //~ {
    //~ var x = coord.x + xd;
    //~ var y = coord.y + yd;
//~
    //~ var width = grid[0].length;
    //~ while (x < 0) x += width;
    //~ while (x >= width) x -= width;
//~
    //~ var height = grid.length;
    //~ while (y < 0) y += height;
    //~ while (y >= height) y -= height;
//~
    //~ return { x: x, y: y };
  //~ }
}
