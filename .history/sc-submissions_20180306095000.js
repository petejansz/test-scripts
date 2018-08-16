var http = require("https");

var options = {
  "method": "POST",
  "hostname": "mobile-cat.calottery.com",
  "port": null,
  "path": "/api/v1/second-chance/players/self/submissions",
  "headers": {
    "content-type": "application/json",
    "x-ex-system-id": "8",
    "x-channel-id": "3",
    "x-site-id": "35",
    "x-esa-api-key": "DBRDtq3tUERv79ehrheOUiGIrnqxTole",
    "x-method": "scan",
    "authorization": "OAuth NRiXdeUA9edyE8zo29g-3w",
    "x-device-uuid": "abcd12345fewflkjsfkjlenfjklrheigerg564564536gregreg35g4r34re63g56erg",
   "cache-control": "no-cache",
    "postman-token": "e5f71707-2414-889f-4eaf-94f803e387d5"
  }
};

var req = http.request(options, function (res) {
  var chunks = [];

  res.on("data", function (chunk) {
    chunks.push(chunk);
  });

  res.on("end", function () {
    var body = Buffer.concat(chunks);
    console.log(body.toString());
  });
});

req.write(JSON.stringify({ type: '.ScratcherSubmissionDTO',
  entryCode: '10156254588370000001',
  ticketId: '' }));
req.end();
