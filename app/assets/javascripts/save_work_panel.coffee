onLoad = ()->

  $('.toggle').on('click', ()->
    shownPanel = $(this).siblings('.togglePanel').slideDown(200)
    $('.togglePanel').not(shownPanel).slideUp(200)
  )

  $('.togglePanel').hide()

$(window).bind('turbolinks:load', onLoad)
