class ImgLoader
{
  static var loading : Int = 0;

  public static function get(path : String) : Dynamic
  {
    var img : Dynamic = untyped __js__("new Image()");

    loading++;

    img.onload = img.onerror = img.onabort = finish;
    img.src = path;

    return img;
  }

  public static inline function isDone() : Bool return loading == 0

  static function finish()
  {
    loading--;
  }
}
