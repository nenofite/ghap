using Utils;

class Terrain
{
  public static inline var spriteW = 30;
  public static inline var spriteH = 30;

  public static inline var varianceX = 10;
  public static inline var varianceY = 10;

  public static var forest : Terrain;
  public static var grass  : Terrain;
  public static var water  : Terrain;
  public static var rock   : Terrain;

  public var name(default, null) : String;

  public var tile(default, null) : Dynamic;
  var sprites : Array<ProbSprite>;

  public function new(name, tile, sprites)
  {
    this.name = name;
    this.tile = tile;
    this.sprites = sprites;
  }

  public static function init()
  {
    //~ var grass_bg = ImgLoader.get("grass.png");
    //~ var rock_spr = ImgLoader.get("rock sprite.png");
    //~ var grass_spr = ImgLoader.get("grass tuft.png");
//~
    //~ forest = new Terrain("Forest", Images.i.i.grassBg, [{ sprite: ImgLoader.get("tree.png"), prob: 0.8 }]);
    //~ grass = new Terrain("Grass", grass_bg, [{ sprite: rock_spr, prob: 0.05 }, { sprite: grass_spr, prob: 0.8 }]);
    //~ water = new Terrain("Water", ImgLoader.get("water.png"), []);
    //~ rock = new Terrain("Rock", ImgLoader.get("rock.png"), [{ sprite: rock_spr, prob: 0.5 }]);

    forest = new Terrain("Forest", Images.i.grassBg, [{ sprite: Images.i.tree, prob: 0.8 }, { sprite: Images.i.grass, prob: 0.1 }, { sprite: Images.i.rock, prob: 0.05 }]);
    grass = new Terrain("Grass", Images.i.grassBg, [{ sprite: Images.i.rock, prob: 0.05 }, { sprite: Images.i.grass, prob: 0.8 }]);
    water = new Terrain("Water", Images.i.waterBg, []);
    rock = new Terrain("Rock", Images.i.rockBg, [{ sprite: Images.i.rock, prob: 0.5 }]);
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
