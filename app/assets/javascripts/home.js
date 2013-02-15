$(function(){
    $(".tablesorter:has(tbody tr)").tablesorter();

    $(".btn").tooltip();

    $(".tooltip").tooltip();

    $(".delete_me").on("click", function(e){
        e.preventDefault();
        var id = $(this).attr("data-id");
        var tp = $(this).attr("data-type");
        var tr = $(this).parent("td").parent("tr");
        if (id != "nil" && tp != "unknown") {
            var u = "/"+tp+"/"+id+".json";
            console.log("delete_me:"+u);
            d = {
                _method: "DELETE"
            };
            $.post(u, d, function(){
                console.log("returned");
                if (tr) {
//                    $(tr).fadeOut(500, function(){ $(this).remove();})
                    $(tr).addClass("deleting");
                }
            });
        }
    });

    $(".protected").on("click", function(e){
        bootbox.alert("must remove protection first")
    });

    $(".account_select").on("click", function(e){
        e.preventDefault();
        var a = $(this).attr("data-account");
        if (console) {
            console.log("select account: "+a);
        }
        $.post("/accounts/"+a+"/select", {}, function(d) {
            console.log(d);
            window.location.reload();
        });
    });

});

