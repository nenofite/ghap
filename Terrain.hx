using Utils;

class Terrain
{
  public static inline var spriteW = 30;
  public static inline var spriteH = 30;

  public static inline var varianceX = 10;
  public static inline var varianceY = 10;

  public var name(default, null) : String;

  public var tile(default, null) : Dynamic;
  var sprites : Array<ProbSprite>;

  public function new(name, tile, sprites)
  {
    this.name = name;
    this.tile = tile;
    this.sprites = sprites;
  }

  public inline function iterSprites() : Iterator<ProbSprite>
  {
    return sprites.iterator();
  }

  public function getSprite(rand : Rand) : SprInfo
  {
    var x = Math.round((rand.next() * 2 - 1) * varianceX);
    var y = Math.round((rand.next() * 2 - 1) * varianceY);
    var sprite : Dynamic = null;

    var prob = rand.next();
    for (ps in sprites) {
      prob -= ps.prob;
      if (prob <= 0) {
        sprite = ps.sprite;
        break;
      }
    }

    return { x: x, y: y, sprite: sprite };
  }
}

typedef ProbSprite = { prob : Float, sprite : Dynamic };
typedef SprInfo = { x : Int, y : Int, sprite : Dynamic };
