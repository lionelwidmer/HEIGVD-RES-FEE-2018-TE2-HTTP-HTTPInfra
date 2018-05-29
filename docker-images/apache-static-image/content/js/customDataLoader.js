$(function() {
	console.log("Loading data");

	function loadData() {
		$.getJSON( "/api/students/", function (companies) {
			console.log(companies);
			var message = "Nobody is here";
			if (companies.length > 0 ) {
				message = companies[0].company + " - " + companies[0].domain;
			}
			$(".text-faded").text(message);
		});
	};

	loadData();
	setInterval( loadData, 2000);
});
