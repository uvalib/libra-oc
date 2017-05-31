  function initPage() {

    function lookup(cid_field) {
      var cid = cid_field.val();
      var outerForm = $(cid_field).parents('.person-group');
      var personType = outerForm.data("persontype")
      var index = outerForm.data("index");

      function onSuccess(resp) {
        console.log(resp);
        var elFirstName = outerForm.find(".libra_work_" + personType + "_first_name input").change();
        var elLastName = outerForm.find(".libra_work_" + personType + "_last_name input");
        var elDepartment = outerForm.find(".libra_work_" + personType + "_department input");
        var elInstitution = outerForm.find(".libra_work_" + personType + "_institution input");
        if (resp.cid) {
          // The computing id was found if the object returned is not empty.
          elFirstName.val(resp.first_name);
          elLastName.val(resp.last_name);
          elDepartment.val(resp.department);
          elInstitution.val(resp.institution);
        } else {
          elFirstName.val("");
          elLastName.val("");
          elDepartment.val("");
          elInstitution.val("");
        }
        $("body").trigger("computing_id:change", { index: index });
      }

      $.ajax("/computing_id.json", {
        data: { id: cid, index: index },
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
