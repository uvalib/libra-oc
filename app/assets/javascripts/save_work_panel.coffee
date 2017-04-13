onLoad = ()->

  $("input[name='libra_work[visibility]']").on('change', ()->
    $('input[name="agreement"]').change()
  )

$(window).bind('turbolinks:load', onLoad)
