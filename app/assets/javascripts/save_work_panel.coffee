onLoad = ()->

  $("input[name='libra_work[visibility]']").on('change', ()->
    $('input[name="agreement"]').change()
  )

  $("#fixedSaveWidget").affix({offset: {bottom: 600, top: 300}})


$(window).bind('turbolinks:load', onLoad)

leavingWarning = (event)->
  onEditPage = window.location.href.match(/concern\/libra_works.*(edit|new)/)
  if onEditPage && confirm('If you leave this page, any changes you made will be lost. Are you sure?') == false
    event.stopPropagation()
    false


$(window).bind('turbolinks:before-visit', leavingWarning)
