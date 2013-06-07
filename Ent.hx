using Utils;

class Ent
{
  public static var panda : Panda;
  public static var walriFollowing : Int = 0;

  public var sprite(default, null) : Dynamic;

  public var coord : World.Coord;
  public var alive : Bool;
  public var level(default, null) : Int;
  
  var xp : Int;

  public function new(sprite)
  {
    alive = true;
    this.sprite = sprite;
    level = 1;
    xp = 0;
  }

  public function update(w : World)
  {
    throw "Ent function update() not implemented in class: " + Type.getClassName(Type.getClass(this));
  }

  /// Battles the given foe, with this as the first participant and foe as the second (when displaying)
  /// The winner is awarded XP equivalent to the level of the loser
  /// Mustn't be called when either this or foe is already dead
  public function battle(foe : Ent, w : World)
  {
    if (!foe.alive || !alive) throw "Attempted battle with dead participants: " + this + " vs. " + foe;

    var fr = foe.roll();
    var r = roll();

    w.log(World.Log.Battle(showRoll(r) + "  " + foe.showRoll(fr)));

    if (fr < r) {
      addXp(foe.level, w);
      foe.die(w);
    } else if (fr > r) {
      foe.addXp(level, w);
      die(w);
    }
  }

  public function showRoll(r : Int) : String
  {
    return Type.getClassName(Type.getClass(this)) + " rolls " + r + ".";
  }

  public function roll() : Int
  {
    return Std.random(5 + level) + 1;
  }

  public function die(w : World)
  {
    alive = false;
  }
  
  /// increments xp, then levels up to the resulting level
  /// decrements xp with every level up
  /// only calls setLevel() once
  public function addXp(inc : Int, w : World)
  {
    xp += inc;
    
    var newLevel = level;
    while (xp >= xpForLevel(newLevel + 1)) {
      xp -= xpForLevel(newLevel + 1);
      newLevel++;
    }
    
    if (newLevel != level) setLevel(newLevel);
  }
  
  /// Sets level to lev.  May be overridden to display achievements,
  /// change sprites, or whatever in order to reflect the new level
  public function setLevel(lev : Int)
  {
    level = lev;
  }

  public static function isWalkTraversible(t : Terrain) : Bool
  {
    return t != Terrain.water;
  }

  public static function isAmphTraversible(t : Terrain) : Bool
  {
    return true;
  }
  
  /// How much XP is needed to level up from n - 1 to n, where n is the
  /// given level?
  /// Note that xp is not cumulative, it is consumed by leveling up
  public static function xpForLevel(level : Int) : Int
  {
    return (level - 1) * 3;
  }
}

class Player extends Ent
{
  public static var p : Player;

  public var dir : PlayerDir;
  public var onWalrus : Walrus;

  public function new()
  {
    super(Images.i.player);
    p = this;
    onWalrus = null;
  }

  public static function init()
  {
    p = new Player();
  }

  public override function update(w : World)
  {
    if (dir == null) throw "Player has no dir!";

    switch (dir) {
      case Move(c):
        c.x += coord.x;
        c.y += coord.y;
        if (w.inBounds(c)) {
          var e = w.entAt(c);
          if (e != null) {
            if (e.alive) {
              switch (Type.getClass(e)) {
              case Walrus:
                if (onWalrus == null) {
                  mountWalrus(cast e, w);
                }
              case Panda:
                w.win();
              case Zombie:
                battle(e, w);
              }
            }
          } else {
            var type = w.tileAt(c).type;
            var traversible = if (onWalrus != null) Ent.isAmphTraversible(type) else Ent.isWalkTraversible(type);
            if (traversible) w.moveEnt(coord, c);
          }
        }
      case Dismount:
        dismountWalrus(w);
    }

    dir = null;
  }
  
  /// Same as super function except also adds in Walrus's level when mounted
  public override function roll() : Int
  {
    var cap = 5 + level;
    if (onWalrus != null) cap += onWalrus.level;
    return Std.random(cap) + 1;
  }

  public override function die(w : World)
  {
    if (onWalrus != null) dismountWalrus(w);
    super.die(w);
    w.lose();
  }
  
  /// Logs the gain in XP then calls the super
  /// Assumes that the only time this gets called is when Player defeats a foe
  public override function addXp(inc : Int, w : World)
  {
    w.log(World.Log.Xp("You gain " + inc + " XP."));
    super.addXp(inc, w);
    Achievement.aFirstKill.qualify();
  }
  
  /// Runs the super function, then displays a level up banner
  /// Note: always displays banner, regardless of previous level
  public override function setLevel(lev : Int)
  {
    super.setLevel(lev);
    View.v.levelUpBanner(lev);
  }

  public override function showRoll(r : Int) : String
  {
    return "You roll " + r + ".";
  }

  public function mountWalrus(e : Walrus, w : World)
  {
    setOnWalrus(e);
    var c = e.coord;
    w.removeEnt(c);
    w.moveEnt(coord, c);
  }

  public function dismountWalrus(w : World)
  {
    var newCoord : World.Coord = null;
    for (c in coord.getNeighbors()) {
      if (w.inBounds(c) && w.tileAt(c).type != Terrain.water && w.entAt(c) == null) {
        newCoord = c;
        break;
      }
    }
    if (newCoord != null) {
      var oldCoord = coord;
      w.moveEnt(coord, newCoord);
      w.addEnt(oldCoord, onWalrus);
      setOnWalrus(null);
    } else {
      w.log(World.Log.Error("There is no room to dismount."));
    }
  }
  
  /// Makes the character 'like new'
  /// Resets alive, dismounts walrus, XP, level
  /// Achievements are *not* reset
  public function reset()
  {
    setOnWalrus(null);
    alive = true;
    xp = 0;
    level = 1;
  }
  
  function setOnWalrus(val : Walrus)
  {
    onWalrus = val;
    sprite = if (onWalrus == null) Images.i.player else Images.i.playerWalrus;
  }
  
  public function addBindings(v : View)
  {
    var moveU = function() {
      dir = PlayerDir.Move({ x: 0, y: -1 });
      v.world.updateEnts();
    };
    v.binder.binds([104, 73], moveU); // keypad '8', clockwise; standard keyboard 'i' clockwise
    v.arr_u.onclick = moveU;
    
    var moveUR = function() {
      dir = PlayerDir.Move({ x: 1, y: -1 });
      v.world.updateEnts();
    };
    v.binder.binds([105, 79], moveUR);
    v.arr_ur.onclick = moveUR;
    
    var moveR = function() {
      dir = PlayerDir.Move({ x: 1, y: 0 });
      v.world.updateEnts();
    };
    v.binder.binds([102, 76], moveR);
    v.arr_r.onclick = moveR;
    
    var moveDR = function() {
      dir = PlayerDir.Move({ x: 1, y: 1 });
      v.world.updateEnts();
    };
    v.binder.binds([99, 190], moveDR);
    v.arr_dr.onclick = moveDR;
    
    var moveD = function() {
      dir = PlayerDir.Move({ x: 0, y: 1 });
      v.world.updateEnts();
    };
    v.binder.binds([98, 188], moveD);
    v.arr_d.onclick = moveD;
    
    var moveDL = function() {
      dir = PlayerDir.Move({ x: -1, y: 1 });
      v.world.updateEnts();
    };
    v.binder.binds([97, 77], moveDL);
    v.arr_dl.onclick = moveDL;
    
    var moveL = function() {
      dir = PlayerDir.Move({ x: -1, y: 0 });
      v.world.updateEnts();
    };
    v.binder.binds([100, 74], moveL);
    v.arr_l.onclick = moveL;
    
    var moveUL = function() {
      dir = PlayerDir.Move({ x: -1, y: -1 });
      v.world.updateEnts();
    };
    v.binder.binds([103, 85], moveUL);
    v.arr_ul.onclick = moveUL;
    
    var dismount = function() {
      if (onWalrus != null) {
        dir = PlayerDir.Dismount;
        v.world.updateEnts();
      }
    };
    v.binder.bind(68, dismount); // 'D'
    v.btn_dismount.onclick = dismount;
  }
}

enum PlayerDir
{
  Move(c : World.Coord);
  Dismount;
}

class Ai extends Ent
{
  public static inline var PathDist = 12;

  var traversible : Terrain -> Bool;
  
  var prevDest : World.Coord = null;
  var path : Array<World.Coord> = null;
  var pathIndex : Int;
  
  function new(sprite, traversible)
  {
    super(sprite);
    this.traversible = traversible;
  }
  
  /// Abstract, must be overridden
  /// Where this Ai wants to go
  /// This can be null, in which case Ai.update() will not do anything
  /// The destination should be <= PathDist away from the Ai
  function destination(w : World) : World.Coord
  {
    throw "Destination not implemented in " + Type.getClassName(Type.getClass(this));
    return null;
  }
  
  /// Moves the Ai toward its given destination
  /// Will attempt to move in a beeline, but it hits obstacles it will
  /// route a path
  /// This will call destination() at most once per call
  /// Whenever this is called, the Ai is not at its requested destination, and
  /// there exists a route between it and its destination, this method
  /// will move the Ai one square.  There are no cases where it will wait
  /// a tick before moving
  public override function update(w : World)
  {
    var dest = destination(w);
    if (dest == null) {
      path = null;
      prevDest = null;
      return;
    }
    if (!prevDest.equals(dest)) {
      path = null;
      prevDest = dest;
    }
    
    if (coord.equals(dest)) {
      path = null;
      return;
    }
    
    var dir = if (path == null) null else path[pathIndex--];
    
    if (dir != null && traversible(w.tileAt(dir).type) && w.entAt(dir) == null) {
      w.moveEnt(coord, dir);
    } else {
      var fn = function(terr, c) return coord.distanceTo(c) <= PathDist && traversible(terr) && w.entAt(c) == null;
      path = w.path(coord, dest, fn);
      if (path == null) return;
      pathIndex = path.length - 3; // skip $-1 because that is our current coord; skip $-2 because we will use it right now
      w.moveEnt(coord, path[path.length - 2]);
    }
  }
}

class Walrus extends Ai
{
  public function new(level)
  {
    super(Images.i.walrus, Ent.isAmphTraversible);
    setLevel(level);
  }
  
  /// Goes to first Zombie within 6 radius of here, otherwise toward
  /// Player if between 3 and 9 tiles inclusive from here
  override function destination(w : World) : World.Coord
  {
    for (c in coord.getRadius(6)) {
      var e = w.entAt(c);
      if (e != null && e.alive && Type.getClass(e) == Zombie) return c;
    }
    
    var playerCoord = Player.p.coord;
    var dist = coord.distanceTo(playerCoord);
    if (dist <= 9 && dist >= 3) return playerCoord;
    
    return null;
  }

  /// Battles one adjacent Zombie, otherwise calls super
  public override function update(w : World)
  {
    for (c in coord.getNeighbors()) {
      if (w.inBounds(c)) {
        var e = w.entAt(c);
        if (e != null && e.alive && Type.getClass(e) == Zombie) {
          battle(w.entAt(c), w);
          return;
        }
      }
    }

    super.update(w);
  }
}

class Zombie extends Ai
{
  public function new(level)
  {
    super(Images.i.zombie, Ent.isWalkTraversible);
    setLevel(level);
  }
  
  /// Calls the super first
  /// Updates the sprite: if level >= 3, tophat, otherwise normal
  public override function setLevel(lev : Int)
  {
    super.setLevel(lev);
    sprite = if (lev >= 3) Images.i.zombieTophat else Images.i.zombie;
  }
  
  /// Goes toward the player when they are within 9 units inclusive away
  override function destination(w : World) : World.Coord
  {
    var playerCoord = Player.p.coord;
    var dist = coord.distanceTo(playerCoord);
    return if (dist <= 9) playerCoord else null;
  }

  /// Attacks the player when adjacent, otherwise calls super
  public override function update(w : World)
  {
    var player = Player.p;

    for (c in coord.getNeighbors()) {
      if (w.inBounds(c) && w.entAt(c) == player) {
        battle(player, w);
        return;
      }
    }
    
    super.update(w);
  }
}

class Panda extends Ent
{
  public function new()
  {
    super(Images.i.panda);
    Ent.panda = this;
  }

  public override function update(w : World)
  {
    if (Std.random(10) == 0) {
      var opts = new Array<World.Coord>();
      for (c in coord.getNeighbors()) {
        if (w.inBounds(c) && w.entAt(c) == null && Ent.isWalkTraversible(w.tileAt(c).type))
          opts.push(c);
      }
      if (opts.length > 0) {
        w.moveEnt(coord, opts[Std.random(opts.length)]);
      }
    }
  }
}
