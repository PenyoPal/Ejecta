ejecta.require('lib/underscore-min.js');

var ScenePicker = {};

(function() {

function createPattern(director, color) {
  var actor= new CAAT.Actor().
    setSize(director.width, director.height).
    enableEvents(false);

  actor.paint= function( director, time ) {
    var i,j,ctx;
    if ( this.backgroundImage ) {
      this.backgroundImage.paint(director,0,0,0);
      return;
    }
    ctx = director.ctx;
    for( j=0.5; j<director.width; j+=20 ) {
      ctx.moveTo( j, 0 );
      ctx.lineTo( j, director.height );
    }
    for( i=0.5; i<director.height; i+=20 ) {
      ctx.moveTo( 0, i );
      ctx.lineTo( director.width, i );
    }
    ctx.strokeStyle= color;
    ctx.stroke();
  };
  return actor;
}

ScenePicker = _.extend(ScenePicker, {

  director: null,

  start: function () {
    this.scene = this.director.createScene();
    this.scene.setFillStyle('#000');
    this.scene.addChild(createPattern(this.director, '#33f'));
    var choices = [
      {name: 'First Game'},
      {name: 'Second Game'},
      {name: 'Third Game'}
    ];
    var actors = [];
    _.each(choices, function(choice) {
        actors.push(new CAAT.Actor().
          setBounds(100, 100, 500, 300).
          setFillStyle('#0000ff').
          enableDrag());
    });
    this.scene.addChild(actors[0]);
  }

});
})();
