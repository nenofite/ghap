class Rand
{
  var seed : Float;

  static inline var a = 48271;
  static inline var m = 2147483647;
  static inline var oneOverM = 4.65661287525e-10;
  static inline var q = 44488.0704149;
  static inline var r = 3398.9976379;

  public function new(seed)
  {
    this.seed = seed;
  }

  public function next() : Float
  {
    var hi = seed / q;
    var lo = seed % q;
    var test = a * lo - r * hi;
    if (test > 0) {
      seed = test;
    } else {
      seed = test + m;
    }
    return seed * oneOverM;
  }
}
