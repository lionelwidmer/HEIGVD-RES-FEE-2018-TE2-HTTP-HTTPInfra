var Chance = require('chance');
var os = require('os');
var chance = new Chance();

var express = require('express');
var app = express();

app.get('/', function(req, res) {
	res.send(generatePayload());
});

app.listen(3000, function() {
	console.log('Accepting HTTP requests on port 3000');
});

function generatePayload() {
	var numberOfItems = chance.integer({
		min: 0,
		max: 50
	});
	var datas = [];
	for (var i = 0; i < numberOfItems; i++) {
		var company = chance.company()
		var domain = chance.domain();
		var ip = chance.ip();
		var picture = chance.url({
			domain: 'www.' + domain,
			extensions: ['gif', 'jpg', 'png']
		});

		datas.push({
			company: company,
			domain: domain,
			ip: ip,
			picture: picture,
			hostname: os.hostname()
		});
	};

	return datas;
}

