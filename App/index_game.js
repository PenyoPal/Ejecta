var w = window.innerWidth;
var h = window.innerHeight;
var w2 = w/2;
var h2 = h/2;

var canvas = document.getElementById('canvas');
canvas.width = w;
canvas.height = h;

ejecta.require('scene_picker.js');
ejecta.require('lib/caat/caat.js');

Array.prototype.randomElement = function () {
  return this[Math.floor(Math.random() * this.length)];
};

var Game = {};

Game.Character = function(director) {
  var meta = {
    height_choices: ["s","t"],
    weight_choices: ["s","f"],
    color_choices: ["blue","purple","red"],
    item_choices: ["glasses","hat","scarf"], // TODO: null option
    mood_choices: ["angry","happy","sad"],
    dimensions: {
      ss: [231,239],
      sf: [231,239],
      ts: [300,462],
      tf: [300,462]
    }
  };

  var c = {
    height: meta.height_choices.randomElement(),
    weight: meta.weight_choices.randomElement(),
    color: meta.color_choices.randomElement(),
    item: meta.item_choices.randomElement(),
    mood: meta.mood_choices.randomElement(),
    images: {
      face: new Image(),
      body: new Image(),
      item: new Image()
    }
  };

  var path = "assets/persons/";
  var ext = ".png";

  c.images.face.src = path + c.height + c.weight + "-" + c.color + "-" + c.mood + ext;
  c.images.body.src = path + c.height + c.weight + "-" + c.color + ext;
  c.images.item.src = path + c.height + c.weight + "-" + c.item + ext;

  var cActor = new CAAT.ActorContainer().
    setBounds(0,0,300,462);

  setTimeout(function(){ // HACK: timeout so that images have a chance to load
      var x = 300, y = 462;

      var face = new CAAT.Actor().
      setBackgroundImage(c.images.face, true).
      setLocation((x-c.images.body.width)/2, (y-c.images.body.height));

      var body = new CAAT.Actor().
      setBackgroundImage(c.images.body, true).
      setLocation((x-c.images.body.width)/2, (y-c.images.body.height));

      var item = new CAAT.Actor().
      setBackgroundImage(c.images.item, true).
      setLocation((x-c.images.body.width)/2, (y-c.images.body.height));

      cActor.addChild(body);
      cActor.addChild(face);
      cActor.addChild(item);
    }, 50);

  cActor.data = c;

  return cActor;
};


function setupCAAT() {
  function __scene(director) {
    var scene = director.createScene();
    var bg = new CAAT.ActorContainer().
      setBounds(0,0,director.width,director.height).
      setFillStyle('#000000');
    scene.addChild(bg);
    var character = new Game.Character();
    bg.addChild(character);
  }

  var director = new CAAT.Director().initialize(w, h, canvas);
  ScenePicker.director = director;
  ScenePicker.start();
  CAAT.loop(60);
}

setupCAAT();
