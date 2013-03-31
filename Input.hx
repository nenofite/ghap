class Input<T>
{
  static var table : Dynamic = js.Lib.document.getElementById("ctl_table");

  public var label(default, null) : String;
  public var value(default, null) : T;
  public var onChange : T -> Void = null;

  var elem : Dynamic;
  var parse : String -> T;

  public function new(label, value, parse)
  {
    this.label = label;
    this.value = value;
    this.parse = parse;

    elem = js.Lib.document.createElement("input");
    elem.value = "" + value;

    var td1 : Dynamic = js.Lib.document.createElement("td");
    td1.appendChild(elem);

    var label_el : Dynamic = js.Lib.document.createElement("label");
    label_el.innerHTML = label;

    var td2 : Dynamic = js.Lib.document.createElement("td");
    td2.appendChild(label_el);

    var tr : Dynamic = js.Lib.document.createElement("tr");
    tr.appendChild(td2);
    tr.appendChild(td1);

    table.appendChild(tr);

    tr.onchange = handler;
  }

  function handler()
  {
    elem.value = value = parse(elem.value);
    if (onChange != null) onChange(value);
  }
}
