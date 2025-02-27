  function initPage() {

    function lookup(cid_field) {
      var cid = cid_field.val();
      var outerForm = $(cid_field).parents('.person-group');
      var personType = outerForm.data("persontype")

      function onSuccess(resp) {
        console.log(resp);
        var elFirstName = outerForm.find(".libra_work_" + personType + "_first_name input");
        var elLastName = outerForm.find(".libra_work_" + personType + "_last_name input");
        var elDepartment = outerForm.find(".libra_work_" + personType + "_department input");
        var elDepartmentOptions = elDepartment.parent().siblings('.department-options')
        var elInstitution = outerForm.find(".libra_work_" + personType + "_institution input");
        elDepartment.attr('placeholder', '')
        elDepartmentOptions.empty();


        if (resp.cid) {
          // The computing id was found if the object returned is not empty.
          elFirstName.val(resp.first_name);
          elLastName.val(resp.last_name);

           if(resp.department && resp.department.length > 1){
             elDepartment.attr('placeholder', 'Enter or copy from below')
             var departments = resp.department.join('</br>')
             elDepartmentOptions.html( departments );
           } else {
             elDepartment.val(resp.department[0]);
           }


          elInstitution.val(resp.institution);
        } else {
          elFirstName.val("");
          elLastName.val("");
          elDepartment.val("");
          elInstitution.val("");
        }
        elFirstName.change();
      }

      $.ajax("/computing_id.json", {
        data: { id: cid },
        success: onSuccess
      });
    }

    var body = $("body");
    body.on("keyup change", ".id-lookup", function() {
      var cid_field = $(this);
      lookup(cid_field);
    });

  }

  $(window).bind('turbolinks:load', function() {
    initPage();
  });
