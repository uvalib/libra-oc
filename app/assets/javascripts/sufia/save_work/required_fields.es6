export class RequiredFields {
  // Monitors the form and runs the callback if any of the required fields change
  constructor(form, callback) {
    this.form = form
    this.callback = callback
    this.reload()
  }

  // modified to decorate the required fields so we can style them
  get areComplete() {
      var incomplete = 0
      for( let value of this.requiredFields ) {
          if( this.isValueEmpty( value ) === false ) {
              $(value).removeClass( 'invalid-input' )
          } else {
              $(value).addClass( 'invalid-input' )
              incomplete += 1
          }
      }
      return incomplete === 0
  }

  isValueEmpty(elem) {
    return ($(elem).val() === null) || ($(elem).val().length < 1)
  }

  // Reassign requiredFields because fields may have been added or removed.
  reload() {
    // ":input" matches all input, select or textarea fields.
    this.requiredFields = this.form.find(':input[required]')
    this.requiredFields.change(this.callback)
  }
}
