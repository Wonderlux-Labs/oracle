function increaseSpeed() {
  speed = window.pJSDom[0].pJS.particles.move.speed
  console.log(speed);
  if (speed < 20)
    speed += 3;
  else
    speed = 3;
    clearInterval(increaseSpeed);
  window.pJSDom[0].pJS.particles.move.speed = speed
}

function showText(text) {
  $('#fortune').text(text);
  $('#fortune').fadeIn(500);
  setTimeout($('#fortune').fadeOut(5000), 25000)
}

function fortuneTeller(message) {
  interval = setInterval(function(){
    speed = window.pJSDom[0].pJS.particles.move.speed
    console.log(speed);
    if (speed < 30) {
      speed += 1
    }
    else {
      speed = 3;
      clearInterval(interval);
      showText(message)
    }
    window.pJSDom[0].pJS.particles.move.speed = speed
  }, 200)
}

$( document ).ready(function() {
  console.log('hello')
  var url = 'http://0.0.0.0:9292/faye'
  var client = new Faye.Client(url, {retry: 5});
  client.disable('websocket');
  console.log('subscribing')
  client.subscribe('/fortune', function(message) {
    fortuneTeller(message.text);
  });
});
