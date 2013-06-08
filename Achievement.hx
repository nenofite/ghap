class Achievement
{
  public static var aFineSteed = new Achievement("Fine Steed", "Mount a walrus of at least level 3.", Images.i.aFineSteed);
  public static var aFirstKill = new Achievement("First Kill", "Defeat your first zombie.", Images.i.aFirstKill);
  public static var aPopular = new Achievement("Popular", "Have at least 10 walri follow you.", Images.i.aPopular);

  var name : String;
  var desc : String;
  var img : Dynamic;
  
  public var earned(default, null) : Bool = false;
  
  public function new(name, desc, img)
  {
    this.name = name;
    this.desc = desc;
    this.img = img;
  }
  
  /// If this achievement isn't already earned, then earns it and displays
  /// its banner
  public inline function qualify()
  {
    if (!earned) _qualify();
  }
  
  /// Sets earned to true
  /// Constructs, appends, and schedules the banner for this achievement
  /// Adds achievement to the list in the Achievements dialog
  function _qualify()
  {
    earned = true;
    
    var li = js.Lib.document.createElement("li");
    li.innerHTML = name;
    li.title = desc;
    View.v.ul_achv.appendChild(li);
    View.v.dia_achievements.resize();
    
    var div = js.Lib.document.createElement("div");
    div.className = "achv";
    
    var image = js.Lib.document.createElement("img");
    image.className = "achv_img";
    (cast image).src = img;
    div.appendChild(image);
    
    var type = js.Lib.document.createElement("div");
    type.className = "type";
    type.innerHTML = "ACHIEVEMENT";
    div.appendChild(type);
    
    var a_title = js.Lib.document.createElement("div");
    a_title.className = "a_title";
    a_title.innerHTML = name;
    div.appendChild(a_title);
    
    var a_desc = js.Lib.document.createElement("div");
    a_desc.className = "a_desc";
    a_desc.innerHTML = desc;
    div.appendChild(a_desc);
    
    View.v.achievements.appendChild(div);
    View.v.scheduleBanner(div);
  }
}
