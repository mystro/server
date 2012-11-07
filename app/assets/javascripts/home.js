$(function(){
    $(".tablesorter").tablesorter({
        cancelSelection: true
    });
    $(".btn").tooltip();
    $(".tooltip").tooltip();


    $(".delete_me").on("click", function(e){
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
                    $(tr).fadeOut(500, function(){ $(this).remove();})
                }
            });
        }
        e.preventDefault();
    });
});

