import { RequiredFields } from './required_fields'
import { ChecklistItem } from './checklist_item'
import { UploadedFiles } from './uploaded_files'
import { DepositAgreement } from './deposit_agreement'
import VisibilityComponent from './visibility_component'

/**
 * Polyfill String.prototype.startsWith()
 */
if (!String.prototype.startsWith) {
  String.prototype.startsWith = function(searchString, position){
    position = position || 0;
    return this.substr(position, searchString.length) === searchString;
  };
}

export default class SaveWorkControl {
  /**
   * Initialize the save controls
   * @param {jQuery} element the jquery selector for the save panel
   * @param {AdminSetWidget} adminSetWidget the control for the adminSet dropdown
   */
  constructor(element, adminSetWidget) {
    if (element.length < 1) {
      return
    }
    this.element = element
    this.adminSetWidget = adminSetWidget
    this.form = element.closest('form')
    element.data('save_work_control', this)
    this.activate();
    //$(document).on('keyup', 'input', ()=>{
    //  this.formStateChanged();
    //})
  }

  /**
   * Keep the form from submitting (if the return key is pressed)
   * unless the form is valid.
   *
   * This seems to occur when focus is on one of the visibility buttons
   */
  preventSubmitUnlessValid() {
    this.form.on('submit', (evt) => {
        if (!this.isValid())
        evt.preventDefault();
        })
  }

  /**
   * Keep the form from being submitted many times.
   *
   */
  preventSubmitIfAlreadyInProgress() {
    this.form.on('submit', (evt) => {
        if (this.isValid())
        this.saveButton.prop("disabled", true);
        })
  }

  /**
   * Keep the form from being submitted while uploads are running
   *
   */
  preventSubmitIfUploading() {
    this.form.on('submit', (evt) => {
        if (this.uploads.inProgress) {
        evt.preventDefault()
        }
        })
  }

  /**
   * Is the form for a new object (vs edit an existing object)
   */
  get isNew() {
    return this.form.attr('id').startsWith('new')
  }


  /*
   * Call this when the form has been rendered
   */
  activate() {
    if (!this.form) {
      return
    }
    this.requiredFields = new RequiredFields(this.form, () => this.formStateChanged())
    this.uploads = new UploadedFiles(this.form, () => this.formStateChanged())
    this.saveButton = this.element.find(':submit')
    this.depositAgreement = new DepositAgreement(this.form, () => this.formStateChanged())
    this.requiredMetadata = new ChecklistItem(this.element.find('#required-metadata'))
    this.requiredFiles = new ChecklistItem(this.element.find('#required-files'))
    this.hasExistingFiles = (this.form.find('#libra_work_has_existing_files').val() == 'true')
    new VisibilityComponent(this.element.find('.visibility'), this.adminSetWidget)
    this.preventSubmit()
    this.watchMultivaluedFields()
    this.formChanged()
  }

  preventSubmit() {
    this.preventSubmitUnlessValid()
    this.preventSubmitIfAlreadyInProgress()
    this.preventSubmitIfUploading()
  }

  // If someone adds or removes a field on a multivalue input, fire a formChanged event.
  watchMultivaluedFields() {
    $('.multi_value.form-group', this.form).bind('managed_field:add', () => this.formChanged())
    $('.multi_value.form-group', this.form).bind('managed_field:remove', () => this.formChanged())
  }

  // Called when a file has been uploaded, the deposit agreement is clicked or a form field has had text entered.
  formStateChanged() {
    this.saveButton.prop("disabled", !this.isValid());
  }

  // called when a new field has been added to the form.
  formChanged() {
    this.requiredFields.reload();
    this.formStateChanged();
  }

  isValid() {
    // avoid short circuit evaluation. The checkboxes should be independent.
    let metadataValid = this.validateMetadata()
    let filesValid = this.validateFiles()
    let agreementValid = this.validateAgreement(filesValid)
    return metadataValid  && agreementValid
  }

  // sets the metadata indicator to complete/incomplete
  validateMetadata() {
    if (this.requiredFields.areComplete) {
      this.requiredMetadata.check()
      return true
    }
    this.requiredMetadata.uncheck()
    return false
  }

  // sets the files indicator to complete/incomplete
  validateFiles() {
    if (this.uploads.hasFiles || this.hasExistingFiles ) {
      this.requiredFiles.check()
      return true
    }
    this.requiredFiles.uncheck()
    return false
  }

  validateAgreement(filesValid) {
    var optionalAgreement = this.form.find('input[value=restricted]')[0]
    optionalAgreement = optionalAgreement && optionalAgreement.checked
    if (filesValid && this.uploads.hasNewFiles && this.depositAgreement.mustAgreeAgain && !optionalAgreement) {
      // Force the user to agree again
      this.depositAgreement.setNotAccepted()
      return false
    }
    return this.depositAgreement.isAccepted
  }
}
