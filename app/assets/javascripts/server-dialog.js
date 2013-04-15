$(function(){
    $(".server-dialog").on("click", function(){
        var t = $(this).attr("data-type");
        var u = $(this).attr("data-url");

        console.log("u="+u);
//        $("#server_dialog_contents").load(u, function(d){
//            console.log("server_dialog_contents load");
//        });
        $.get(u)
            .done(function(d){
                console.log("get done");
                console.log(d)
                $("#server_dialog_contents").html(d);
            });
        console.log("dialog...");
        bootbox.dialog($("#server_dialog").html(), [
            {
                "Cancel": function () {
                    console.log("cancel");
                }
            },
            {
                "Create": function () {
                    console.log("create");
                    var f = $(".compute_form:last"); // because bootbox makes a clone
                    data = f.serialize();
                    console.log("data");
                    console.log(f.serializeArray());
                    bootbox.modal("please wait", "creating");
                    console.log("post");
                    $.post("/computes.json", data, function () {
                        console.log("success");
                        bootbox.hideAll();
                    });
                }
            }
        ], {header: "Create "+t})
    });
});
