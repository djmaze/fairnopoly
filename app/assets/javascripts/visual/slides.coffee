$(document).ready ->
  $("#slides").slidesjs
    width: 490
    height: 490
    start: Math.floor(Math.random() * 6)+1 # random number between 1 and 6
    play:
      active: false
      auto: true
      interval: 10000
    pagination:
      active: false
    navigation:
      active: false

  $("#UserSlides").slidesjs
    start: Math.floor(Math.random() * 5)+1 # random number between 1 and 5
    pagination:
      active: false
    navigation:
      active: false
    callback:
      loaded: (n) ->
        $("#Slide#{n}").css('position', 'static')
      complete: (n) ->
        m = if (n-1) == 0 then 5 else (n-1)
        o = if (n+1) == 6 then 1 else (n+1)
        $("#Slide#{m}").css('position', 'absolute')
        $("#Slide#{n}").css('position', 'static')
        $("#Slide#{o}").css('position', 'absolute')
