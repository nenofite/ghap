class Images
{
  public static var i : Dynamic = {
    grassBg: "grass.png",
    rockBg: "rock.png",
    waterBg: "water.png",
    rock: "rock sprite.png",
    grass: "grass tuft.png",
    tree: "tree.png",

    player: "player.png",
    playerWalrus: "player on walrus.png",
    walrus: "walrus.png",
    zombie: "zombie.png",
    zombieTophat: "zombie with tophat.png",
    panda: "panda.png",

    skull: "skull.png",
    selection: "selection.png",
    named: "named.png",
    editName: "edit name.png", // have it preloaded even though we won't use the JS Image
    
    hp: "hp.png",
    emptyHp: "empty hp.png",
    
    heart: "heart.png",
    emptyHeart: "empty heart.png",
    
    hpDot: "hp dot.png",
    emptyHpDot: "empty hp dot.png",

    background: "world bg.png",
    
    levelup: "level up.png", // have it preloaded even though we won't use the JS Image
    aFineSteed: "achv/fine steed.png",
    aFirstKill: "achv/first kill.png",
    aRageQuit: "achv/rage quit.png",
    aPopular: "achv/popular.png",
    
    bHpUp: "bubb/hp up.png",
    bHpDown: "bubb/hp down.png",
  };

  static var loading : Int;
  static var onFinish : Void -> Void;

  public static function init(onFinish)
  {
    var fields = Reflect.fields(i);
    loading = fields.length;

    for (f in fields) {
      var src : String = Reflect.field(i, f);
      var img = untyped __js__("new Image()");
      Reflect.setField(i, f, img);

      img.onload = function() {
        loading--;
        trace("Loading: " + loading);
        if (loading == 0) {
          onFinish();
        }
      };
      img.onabort = img.onerror = function() {
        trace("Error while loading image: " + src);
        img.onload();
      };
      img.src = src;
    }
  }
}
