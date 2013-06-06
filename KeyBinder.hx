class KeyBinder
{
  var bindings : Hash<Void -> Void>;
  var uncaughtF : Int -> Void = null;

  public function new()
  {
    bindings = new Hash();
  }

  public function bind(key : Int, f : Void -> Void)
  {
    bindings.set("" + key, f);
  }
  
  public function binds(keys : Array<Int>, f : Void -> Void)
  {
    for (k in keys) bindings.set("" + k, f);
  }

  public function call(key : Int)
  {
    var f = bindings.get("" + key);
    if (f != null) f();
    else if (uncaughtF != null) uncaughtF(key);
  }

  public function uncaught(f : Int -> Void)
  {
    uncaughtF = f;
  }
}
