// This widget manages the adding and removing of repeating fields.
// There are a lot of assumptions about the structure of the classes and elements.
// These assumptions are reflected in the MultiValueInput class.

var HydraEditor = (function($) {
  var FieldManager = function (element, options) {
    this.element = $(element);
    this.options = options;

    this.controls = $(options.controlsHtml);
    this.remover  = $(options.removeButtonHtml);
    this.adder    = $(options.addButtonHtml);

    this.fieldWrapperClass = options.fieldWrapperClass;
    this.warningClass = options.warningClass;
    this.listClass = options.listClass;

    this.init();
  }

  FieldManager.prototype = {
    init: function () {
      this._addInitialClasses();
      this._appendControls();
      this._attachEvents();
      this._addCallbacks();
    },

    _addInitialClasses: function () {
      this.element.addClass("managed");
      $(this.fieldWrapperClass, this.element).addClass("input-group input-append");
    },

    _appendControls: function() {
      $(this.fieldWrapperClass, this.element).append(this.controls);
      $(this.fieldWrapperClass+':not(:last-child) .field-controls', this.element).append(this.remover);
      $('.field-controls:last', this.element).append(this.adder);
    },

    _attachEvents: function() {
      var _this = this;
      this.element.on('click', '.remove', function (e) {
        var parent = $(this).closest("ul.listing"); // Have to get this before the action because the action removes the element.
        var delete_tag = $(this).parents('li').find('.remove_field').val(1);
        parent.append(delete_tag);
        _this.removeFromList(e);

        $("body").trigger("managed_field:change", { parent: parent, action: "remove" });

        var last_field_controls = parent.find('.field-controls:last')
        if (last_field_controls.find('.add').length == 0) {
          last_field_controls.append(_this.adder);
        }
      });
      this.element.on('click', '.add', function (e) {
        var parent = $(this).closest("ul.listing"); // Have to get this before the action because the action removes the element.
        _this.addToList(e);
        $("body").trigger("managed_field:change", { parent: parent, action: "add" });
      });
    },

    _addCallbacks: function() {
      this.element.bind('managed_field:add', this.options.add);
      this.element.bind('managed_field:remove', this.options.remove);
    },

    addToList: function( event ) {
      event.preventDefault();
      var $activeField = $(event.target).parents(this.fieldWrapperClass)

      if (this.inputIsEmpty($activeField)) {
        this.displayEmptyWarning();
      } else {
        var $listing = $(this.listClass, this.element);
        this.clearEmptyWarning();
        $listing.append(this._newField($activeField));
      }
    },

    inputIsEmpty: function($activeField) {
      return $activeField.find('input[type!="hidden"],select,input.required').val() === '';
    },

    _newField: function ($activeField) {
      var $newField = this.createNewField($activeField);
      // _changeControlsToRemove must come after createNewField
      // or the new field will not have an add button
      this._changeControlsToRemove($activeField);
      return $newField;
    },

    createNewField: function($activeField) {
      $newField = $activeField.clone();
      $newChildren = $newField.find('input');

      newIndex = $activeField.closest("ul.listing").children('li').length;

      $newField.find('label').each( function(){
        var oldLabel = $(this).attr('for');
        var newLabel = oldLabel.replace(new RegExp(/_[0-9]+_/), "_"+newIndex+"_" );
        $(this).attr('for', newLabel);
      });


      $newField.find('select, input').each( function(){
        oldId = $(this).attr('id');
        newId = oldId.replace(new RegExp(/_[0-9]+_/), "_"+newIndex+"_" );
        $(this).attr('id', newId);

        oldName = $(this).attr('name');
        newName = oldName.replace(new RegExp(/\[[0-9]+\]/), "["+newIndex+"]" );
        $(this).attr('name', newName);

        $(this).val('').removeProp('required');
      });
      $newField.find('input.index').val(newIndex)


      $newChildren.first().focus();
      this.element.trigger("managed_field:add", $newChildren.first());
      return $newField;
    },

    _changeControlsToRemove: function($activeField) {
      var $removeControl = this.remover.clone();
      $activeFieldControls = $activeField.children('.field-controls');
      $('.add', $activeFieldControls).remove();
      $('.remove', $activeFieldControls).remove();
      $activeFieldControls.prepend($removeControl);
    },

    clearEmptyWarning: function() {
      $listing = $(this.listClass, this.element),
        $listing.children(this.warningClass).remove();
    },

    displayEmptyWarning: function () {
      $listing = $(this.listClass, this.element)
      var $warningMessage  = $("<div class=\'message has-warning\'>Cannot add new empty field</div>");
      $listing.children(this.warningClass).remove();
      $listing.append($warningMessage);
    },

    removeFromList: function( event ) {
      event.preventDefault();
      this.clearEmptyWarning();

      var field = $(event.target).parents(this.fieldWrapperClass)
      field.remove();

      this.element.trigger("managed_field:remove", field);
    },

    destroy: function() {
      $(this.fieldWrapperClass, this.element).removeClass("input-append");
      this.element.removeClass( "managed" );
    }
  }

  FieldManager.DEFAULTS = {
    /* callback to run after add is called */
    add:    null,
    /* callback to run after remove is called */
    remove: null,


    controlsHtml:      "<span class=\"input-group-btn field-controls\">",
    addButtonHtml:     "<button type=\"button\" class=\"btn btn-success add\"><i class=\"icon-white glyphicon-plus\"></i><span>More</span></button>",
    removeButtonHtml:  "<button type=\"button\" class=\"btn btn-danger remove\"><i class=\"icon-white glyphicon-minus\"></i><span>Remove</span></button>",
    warningClass:      '.has-warning',
    listClass:         '.listing',
    fieldWrapperClass: '.field-wrapper'
  }

  return { FieldManager: FieldManager };
})(jQuery);

(function($){
  $.fn.manage_fields = function(option) {
    return this.each(function() {
      var $this = $(this);
      var data  = $this.data('manage_fields');
      var options = $.extend({}, HydraEditor.FieldManager.DEFAULTS, $this.data(), typeof option == 'object' && option);

      if (!data) $this.data('manage_fields', (data = new HydraEditor.FieldManager(this, options)));
    })
  }
})(jQuery);
