class Map<T>
{
  var map : Dynamic<T>;

  public function new()
  {
    map = {};
  }

  public inline function set(key : String, val : T)
  {
    Reflect.setField(map, key, val);
  }

  public inline function get(key : String) : T
  {
    return Reflect.field(map, key);
  }
}
