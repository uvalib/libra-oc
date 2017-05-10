onLoad = ()->

  $('form#orcid-search-form').on('submit', (e)->
    e.preventDefault()
    startProgress()
    $form = $(this)
    val = $form.find('input#orcid_search_value').val()
    $.get($form.attr('action'), {q: val}, (response)->
      $('#orcid-results-container').html(response)
    , 'html'
    ).always(()->
      $('#orcidSearchSubmit').prop('disabled', false);
      endProgress()
    )
  )

  $(document).on('click', 'a.orcid-pager', (e)->
    e.preventDefault()
    startProgress()
    $.get( $(this).attr('href'), (response)->
      $('#orcid-results-container').html(response)
    , 'html'
    ).always(endProgress)

  )

  $(document).on('click', '.select-orcid', (e)->
    $('#user_orcid').val($(this).data('orcid-id'))
    $('#orcid-name').html($(this).data('orcid-name'))
    $('#orcidSearch').modal('hide')
  )

  $('#clear-orcid').on('click', (e)->
    $('#user_orcid').val('')
    $('#orcid-name').html('')
  )

  startProgress = ()->
    Turbolinks.controller.adapter.progressBar.setValue(0);
    Turbolinks.controller.adapter.progressBar.show();
  endProgress = ()->
    Turbolinks.controller.adapter.progressBar.hide();
    Turbolinks.controller.adapter.progressBar.setValue(100);
$(window).bind('turbolinks:load', onLoad)
