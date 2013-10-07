$(function(){
    $(document).delegate(".mdo-dialog", "click", function(){
        var model = $(this).data("model");
        var options = $(this).data("options");
        $.get("/"+model+"/dialog?"+options, function(data){
            bootbox.dialog(data, [
                {
                    "Cancel": function () {
                        console.log("cancel");
                    }
                },
                {
                    "Create": function () {
                        console.log("create");
                        var f = $("#mdo-dialog-form"); // because bootbox makes a clone
                        form = f.serialize();
                        console.log("data");
                        console.log(f.serializeArray());
                        bootbox.modal("please wait", "creating");
                        console.log("post");
                        $.post("/"+model+".json", form, function () {
                            console.log("success");
                            bootbox.hideAll();
                        }).fail(function(){
                            bootbox.alert("model:"+model+" options:"+options+" save failed")
                        });
                    }
                }
            ], {header: "Create Compute"})
        }).fail(function(){
            bootbox.alert("model:"+model+" options:"+options+" dialog failed");
        });
    });
});
