var interval = null;
function updateStatus() {
    console.log("update status");
    $.get("/api/status", function (d) {
//        console.log("update status return");
//        console.log(d);

        var j = $("#jobs_status").first();
//        console.log(j);
        j.removeClass("badge-important");
        j.text(d["jobs"]["count"]);
        if (d["jobs"]["error"]) {
//            console.log("jobs error true");
            j.addClass("badge-important")
        }

        var r = $("#resque_status").first();
//        console.log(r);
        r.removeClass("badge-important");
        r.text(d["resque"]["count"]);
        if (d["resque"]["error"]) {
//            console.log("resque error true");
            r.addClass("badge-important")
        }

    });
}
$(function () {
    interval = setInterval(updateStatus, 2000);
    $(".tablesorter:has(tbody tr)").tablesorter();

    $(".btn").tooltip();

    $(".tooltip").tooltip();

    $(".delete_me").on("click", function (e) {
        e.preventDefault();
        var id = $(this).attr("data-id");
        var tp = $(this).attr("data-type");
        var tr = $(this).parent("td").parent("tr");
        if (id != "nil" && tp != "unknown") {
            var u = "/" + tp + "/" + id + ".json";
            console.log("delete_me:" + u);
            d = {
                _method: "DELETE"
            };
            $.post(u, d, function () {
                console.log("returned");
                if (tr) {
//                    $(tr).fadeOut(500, function(){ $(this).remove();})
                    $(tr).addClass("deleting");
                }
            });
        }
    });

    $(".accept_me").on("click", function (e) {
        e.preventDefault();
        var id = $(this).attr("data-id");
        var tp = $(this).attr("data-type");
        var tr = $(this).parent("td").parent("tr");
        if (id != "nil" && tp != "unknown") {
            var u = "/" + tp + "/" + id + "/accept.json";
            console.log("accept_me:" + u);
            $.post(u, {}, function () {
                console.log("returned");
                if (tr) {
//                    $(tr).fadeOut(500, function(){ $(this).remove();})
                    $(tr).addClass("deleting");
                }
            });
        }
    });

    $(".protected").on("click", function (e) {
        bootbox.alert("must remove protection first")
    });

    $(".account_select").on("click", function (e) {
        e.preventDefault();
        var a = $(this).attr("data-account");
        if (console) {
            console.log("select account: " + a);
        }
        $.post("/accounts/" + a + "/select", {}, function (d) {
            console.log(d);
            window.location.reload();
        });
    });

    $(".create_job").on("click", function () {
        var c = $(this).attr("klass");
        console.log("create job");
        $.post("/jobs", {job: {_type: c}}, function (d) {
            console.log("create job returned")
        });
    });

    $(".update_status").on("click", function () {
    });

    $(".create_compute").on("click", function () {
        var t = $(this).attr("data-type");
        bootbox.dialog($("#new_compute_dialog_"+t).html(), [
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
        ], {header: "Create Compute"})
    });
    $("#compute_region").on("change", function () {
        console.log("region change");

    });
});