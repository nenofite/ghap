using Utils;

class Ent
{
  public static var panda : Panda;
  public static var walriFollowing : Int = 0;

  public var sprite(default, null) : Dynamic;

  public var coord : World.Coord;
  public var alive : Bool;
  public var level(default, null) : Int;
  
  public var viewDist(default, null) : Int;
  
  public var hp : Int;
  public var maxHp : Int;
  public var xp : Int;
  var healTimer : Int;

  public function new(sprite, viewDist, maxHp)
  {
    alive = true;
    this.sprite = sprite;
    this.viewDist = viewDist;
    level = 1;
    xp = 0;
    hp = this.maxHp = maxHp;
    healTimer = 0;
  }

  /// Updates the Ent for this tick
  /// Only called once per tick
  /// Defaults to calling updateHeal()
  public function update(w : World)
  {
    updateHeal(w);
  }
  
  /// Increments healTimer and calls gainHp() when appropriate
  /// Starts healing 5 ticks after the most recent battle, then every other
  /// tick after that
  /// This should be called once every tick by update()
  public function updateHeal(w : World)
  {
    ++healTimer;
    if (healTimer >= 5) {
      healTimer = 3;
      if (hp < maxHp) gainHp(1, w);
    }
  }

  /// Battles the given foe, with this as the first participant and foe as the second (when displaying)
  /// Resets both Ents' healTimer
  /// Logs the rolls
  /// Calls winRound(), loseRound(), and winBattle() as appropriate
  /// Mustn't be called when either this or foe is already dead
  public function battle(foe : Ent, w : World)
  {
    if (!foe.alive || !alive) throw "Attempted battle with dead participants: " + this + " vs. " + foe;

    healTimer = foe.healTimer = 0;

    var fr = foe.roll();
    var r = roll();

    w.log(World.Log.Battle(showRoll(r) + "  " + foe.showRoll(fr)));

    if (fr < r) {
      var death = foe.loseRound(this, w);
      winRound(foe, w);
      if (death) winBattle(foe, w);
    } else if (fr > r) {
      var death = loseRound(foe, w);
      foe.winRound(this, w);
      if (death) foe.winBattle(this, w);
    }
  }
  
  /// Called when this Ent wins a round in a battle
  /// Defaults to add the appropriate XP
  public function winRound(foe : Ent, w : World)
  {
    addXp(foe.level, w);
  }
  
  /// Called when this Ent loses a round in a battle
  /// Returns true if the Ent has died
  /// Defaults to remove 1 HP
  public function loseRound(foe : Ent, w : World) : Bool
  {
    return loseHp(1, w);
  }
  
  /// Called when this Ent kills its foe in battle
  /// Defaults to doing nothing
  public function winBattle(foe : Ent, w : World)
  {
  }

  public function showRoll(r : Int) : String
  {
    return getName() + " rolls " + r + ".";
  }

  public function roll() : Int
  {
    return Std.random(5 + level) + 1;
  }

  public function die(w : World)
  {
    alive = false;
  }
  
  /// Iterate over the coords within viewDist
  /// Uses getRadius()
  public inline function getVisible() : Iterator<World.Coord>
  {
    return coord.getRadius(viewDist);
  }
  
  /// A human-readable name for this ent, which will be seen
  /// by the player during gameplay.
  /// This should *not* incorporate this Ent's nickname, just its species name
  /// Defaults to class name
  public function getName() : String
  {
    return Type.getClassName(Type.getClass(this));
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
    
    if (newLevel != level) setLevel(newLevel, w);
  }

  /// Returns the the progress towards the next level as a fraction
  /// In other terms, it returns ('current xp' / 'xp for next level')
  public function xpProgress() : Float
  {
    return xp / xpForLevel(level + 1);
  }
  
  /// Increments by the given amount of HP
  /// Caps the HP off at maxHp
  /// Announces the gain on the log
  public function gainHp(inc : Int, w : World)
  {
    hp += inc;
    if (hp > maxHp) hp = maxHp;
    
    w.log(World.Log.Hp(getName() + " gains " + inc + " HP."));
  }
  
  /// Decrements by the given amount of HP
  /// If the lowered HP means death, then die() is called
  /// and this returns true
  /// dec should be positive
  /// Announces the loss on the log
  public function loseHp(dec : Int, w : World) : Bool
  {
    hp -= dec;
    w.log(World.Log.Hp(getName() + " loses " + dec + " HP."));
    
    if (hp <= 0) {
      hp = 0;
      die(w);
      return true;
    }
    
    return false;
  }
  
  /// Sets level to lev.  May be overridden to display achievements,
  /// change sprites, or whatever in order to reflect the new level
  /// World may be null
  /// Displays a message in the log
  public function setLevel(lev : Int, ?w : World)
  {
    level = lev;
    if (w != null) w.log(World.Log.Xp(getName() + " is now level " + lev + "."));
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
    return (level - 1) * 6;
  }
}

class Player extends Ent
{
  public static var p : Player;

  public var dir : PlayerDir;
  public var onWalrus : Walrus;

  public function new()
  {
    super(Images.i.player, View.ViewDist, 3);
    p = this;
    onWalrus = null;
  }

  public static function init()
  {
    p = new Player();
  }

  public override function update(w : World)
  {
    super.update(w);
    
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
                } else {
                  w.swapEnts(coord, c);
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
      case Wait:
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
    if (coord.distanceTo(Ent.panda.coord) <= 3) Achievement.aRageQuit.qualify();
    if (onWalrus != null) dismountWalrus(w);
    super.die(w);
    w.lose();
  }
  
  /// Qualifies for the achievement then calls super
  public override function winBattle(foe : Ent, w : World)
  {
    Achievement.aFirstKill.qualify();
    super.winBattle(foe, w);
  }
  
  /// Logs the gain in XP then calls the super
  public override function addXp(inc : Int, w : World)
  {
    w.log(World.Log.Xp("You gain " + inc + " XP."));
    super.addXp(inc, w);
  }
  
  /// Runs the super function, then displays a level up banner
  /// Note: always displays banner, regardless of previous level
  public override function setLevel(lev : Int, ?w : World)
  {
    super.setLevel(lev, w);
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
    if (e.level >= 3) Achievement.aFineSteed.qualify();
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
    hp = maxHp;
    healTimer = 0;
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
    
    var wait = function() {
      dir = PlayerDir.Wait;
      v.world.updateEnts();
    };
    v.binder.binds([101, 75], wait); // keypad '5', std 'k'
    v.arr_w.onclick = wait;
    
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
  Wait;
  Dismount;
}

class Ai extends Ent
{
  public static inline var PathDist = World.UpdateDist;

  var traversible : Terrain -> Bool;
  
  var prevDest : World.Coord = null;
  var path : Array<World.Coord> = null;
  var pathIndex : Int;
  
  function new(sprite, viewDist, maxHp, traversible)
  {
    super(sprite, viewDist, maxHp);
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
  
  /// Moves the Ai toward its given destination by pathfinding
  /// This will call destination() at most once per call
  /// Whenever this is called, the Ai is not already at its requested destination, and
  /// there exists a route between it and a point closer to its destination, this method
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
    if (coord.equals(dest)) {
      path = null;
      return;
    }
    
    if (!prevDest.equals(dest)) {
      path = null;
      prevDest = dest;
    }
    
    if (pathIndex < 0) path = null;
    
    var dir = if (path == null) null else path[pathIndex--];
    
    if (dir != null && traversible(w.tileAt(dir).type) && w.entAt(dir) == null) {
      w.moveEnt(coord, dir);
    } else {
      var fn = function(terr, c) return Ent.Player.p.coord.distanceTo(c) < PathDist && traversible(terr) && w.entAt(c) == null;
      path = w.path(coord, dest, fn);
      if (path.length <= 1) {
        path = null;
        return;
      }
      pathIndex = path.length - 3; // skip $-1 because that is our current coord; skip $-2 because we will use it right now
      w.moveEnt(coord, path[path.length - 2]);
    }
  }
}

class Walrus extends Ai, implements Nameable
{
  public var name : String;

  public function new(level)
  {
    super(Images.i.walrus, 8, 3, Ent.isAmphTraversible);
    setLevel(level, null);
  }
  
  /// Goes to first Zombie within view, otherwise toward
  /// Player when in view but farther than 2 from here
  /// Increments walriFollowing when the Player's coord is chosen or
  /// the Player's coord would have been chosen but the Walrus is too close
  override function destination(w : World) : World.Coord
  {
    for (c in getVisible()) {
      var e = w.entAt(c);
      if (e != null && e.alive && Type.getClass(e) == Zombie) return c;
    }
    
    var playerCoord = Player.p.coord;
    var dist = coord.distanceTo(playerCoord);
    if (dist <= viewDist) {
      Ent.walriFollowing++;
      if (dist > 2) return playerCoord;
    }
    
    return null;
  }

  /// Battles one adjacent Zombie, otherwise calls super
  public override function update(w : World)
  {
    updateHeal(w);
  
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
    super(Images.i.zombie, 6, 2, Ent.isWalkTraversible);
    setLevel(level, null);
  }
  
  /// Calls the super first
  /// Updates the sprite: if level >= 3, tophat, otherwise normal
  public override function setLevel(lev : Int, ?w : World)
  {
    super.setLevel(lev, w);
    sprite = if (lev >= 3) Images.i.zombieTophat else Images.i.zombie;
  }
  
  /// Goes toward the player when they are within view
  override function destination(w : World) : World.Coord
  {
    var playerCoord = Player.p.coord;
    var dist = coord.distanceTo(playerCoord);
    return if (dist <= viewDist) playerCoord else null;
  }

  /// Attacks the player when adjacent, otherwise calls super
  public override function update(w : World)
  {
    updateHeal(w);
  
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
    super(Images.i.panda, 3, 3);
    Ent.panda = this;
  }

  public override function update(w : World)
  {
    super.update(w);
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

interface Nameable
{
  var name : String;
}
