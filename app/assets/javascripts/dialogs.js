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
                        var singular = f.data("singular");
                        post = f.serializeJSON();
                        console.log("data");
                        console.debug(post);
                        bootbox.modal("please wait", "creating");
                        console.log("post");
                        $.post("/"+model+".json", post, function () {
                            console.log("success");
                            bootbox.hideAll();
                        }).fail(function(){
                            bootbox.hideAll();
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
