onLoad = ()->

  $("input[name='libra_work[visibility]']").on('change', ()->
    $('input[name="agreement"]').change()
  )

  $("#fixedSaveWidget").affix({offset: {bottom: 600, top: 300}})

  if onEditPage()
    $("#search-submit-header").on('click', (e)->
      leavingWarning(e)
    )
    $deleteBtn = $("#uploaded-files .delete-file")
    $deleteBtn.data('confirm', 'If you have not saved recently, any changes you made could be lost. Before deleting this file, click Cancel, then Save your work in Libra.' )


$(window).bind('turbolinks:load', onLoad)

leavingWarning = (event)->
  if onEditPage() && confirm('If you leave this page, any changes you made will be lost. Are you sure?') == false
    event.stopPropagation()
    false
$(window).bind('turbolinks:before-visit', leavingWarning)

onEditPage = ()->
  window.location.href.match(/concern\/libra_works.*(edit|new)/)
