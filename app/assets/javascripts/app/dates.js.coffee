i = document.createElement('input')
i.setAttribute('type', 'date')
window.DATE_INPUT_SUPPORTED = i.type != 'text'

unless DATE_INPUT_SUPPORTED
  datepicker_format = $(document.body).data('datepicker-format')
  $('input[type=date]').datepicker({format: datepicker_format}).blur ->
    hide = => $(this).datepicker('hide')
    setTimeout(hide, 100)
