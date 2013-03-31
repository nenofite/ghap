class Heap<T>
{
  var arr : Array<T>;
  // <0 if a < b
  var compare : T -> T -> Float;

  public function new(compare)
  {
    this.compare = compare;
    arr = new Array();
  }

  public function add(a : T)
  {
    var ind = arr.push(a) - 1;

    while (ind > 0) {
      var par = parent(ind);

      if (compare(arr[ind], arr[par]) > 0) {
        var swap = arr[par];
        arr[par] = arr[ind];
        arr[ind] = swap;
        ind = par;
      } else break;
    }
  }

  public function pop() : T
  {
    if (arr.length == 0) return null;

    var top = arr[0];
    removeIndex(0);
    return top;

    //~ var top = arr[0];
    //~ if (arr.length > 1) {
      //~ arr[0] = arr.pop();
      //~ bubble
      //~
      //~ var length = arr.length;
//~
      //~ var head : Int = 0;
      //~ while (head < length) {
        //~ var child = rChild(head);
        //~ if (child < length) {
          //~ if (compare(arr[child - 1], arr[child]) > 0) --child;
        //~ } else --child;
        //~ if (child >= length) break;
        //~ if (compare(arr[child], arr[head]) > 0) {
          //~ var swap = arr[head];
          //~ arr[head] = arr[child];
          //~ arr[child] = swap;
          //~ head = child;
        //~ } else break;
      //~ }
    //~ } else {
      //~ arr = [];
    //~ }
//~
    //~ return top;
  }

  public function remove(a : T)
  {
    var ind : Int = -1;

    var len = arr.length;
    for (i in 0...len) {
      if (arr[i] == a) {
        ind = i;
        break;
      }
    }

    if (ind != -1) {
      removeIndex(ind);
    }
  }

  public function removeIndex(ind : Int)
  {
    if (ind != arr.length - 1) {
      arr[ind] = arr.pop();
      bubble(ind);
    } else arr.pop();
  }

  function bubble(ind : Int)
  {
    var length = arr.length;
    while (ind < length) {
      var child = rChild(ind);
      if (child < length) {
        if (compare(arr[child - 1], arr[child]) > 0) --child;
      } else --child;
      if (child >= length) break;
      if (compare(arr[child], arr[ind]) > 0) {
        var swap = arr[ind];
        arr[ind] = arr[child];
        arr[child] = swap;
        ind = child;
      } else break;
    }
  }

  inline function parent(ind : Int) : Int
  {
    if (ind <= 0) throw "Cannot get parent of index: " + ind;

    return Math.ceil(ind / 2 - 1);
  }

  inline function rChild(ind : Int) : Int
  {
    return (ind + 1) * 2;
  }
}
