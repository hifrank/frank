
/**
* Module dependencies.
*/
var promotion_data_dir = '/tmp/ehs_promotion_mock_api';
var express = require('express');

var app = module.exports = express.createServer();


// Configuration

app.configure(function(){
	app.set('views', __dirname + '/views');
	app.set('view engine', 'jade');
	app.use(express.bodyParser());
	app.use(express.methodOverride());
	app.use(app.router);
	app.use(express.static(__dirname + '/public'));
});

app.configure('development', function(){
	app.use(express.errorHandler({ dumpExceptions: true, showStack: true })); 
});

app.configure('production', function(){
	app.use(express.errorHandler()); 
});

// Routes

app.get('/', function(req, res){
	res.render('index', {
		title: 'Express'
	});
});

var fs = require('fs');
var updatePromotion = function(pid, promotion_obj){
	var p_path = promotion_data_dir+'/' + pid;
	try {
		fs.writeFileSync(p_path, JSON.stringify(promotion_obj));
		console.log('promotion [' + p_path + '] updated completed');
	}
	catch (err) {
		console.log('write file '+p_path+' fail');
		console.log(err);
	}
}
var createPromotion = function(guids){
	var pid = 1, files;
	try {
		files = fs.readdirSync(promotion_data_dir);
	}
	catch (err) {
		//create directory when not exist.
		fs.mkdirSync(promotion_data_dir,'744');
		console.log("create directory:"+promotion_data_dir);
	}
        files.sort(function(a,b){return a - b});
	//change pid when there are already promotions.
	if (files && files.length >= 1){
		pid = parseInt(files[files.length-1])+1;
	}
	var promotion = {
		status: 'processing',
		processing: guids.split(','),
		failed: {},
	};
	console.log(promotion);
	updatePromotion(pid, promotion);
	return pid;
}

app.post('/api/v1/promotion', function(req, res){
	var body = '', postData, msg = '', code = 200;
	postData = req.body
	console.log(postData);
	if (!postData.content_class || !postData.guid || !postData.operator) {
		msg = '{"reason": "required fields not provided"}'
		code = 400;
	}
	//when guid == d40, it return db connection fail.
	else if ('d450' === postData.guid) {
		msg = '{"reason": "Could not connect to database"}';
		code = 500;
	}
	else
	{
		var pid = createPromotion(postData.guid);
		msg = '{"promotion_id": '+pid+'}';
	}
	res.writeHead(code, {'Content-Type': 'text/plain'});
	res.end(msg);
	console.log('end:'+code);
});

app.get('/api/v1/promotion/:pid', function(req, res){
	var code = 200, msg = '', pid = parseInt(req.params.pid);
	var ppath = promotion_data_dir + '/' + pid;
	//promotion id 99 will always fail
	if (0 != (pid % 10)){
		try
		{
			var p_obj = JSON.parse(fs.readFileSync(ppath));
			if ('finished' != p_obj.status)
			{
				var done_obj = p_obj.processing.shift();
				//even promotion id will get fail
				if ((pid % 2 == 0)){
					p_obj.failed[done_obj] = 'Could not find GUID';
				}
				//when processing array is zero, the change the status to "finished"
				if (0 == p_obj.processing.length){
					p_obj.status = 'finished';
				}
				console.log(p_obj)
				//save back to file
				updatePromotion(pid, p_obj);
			}
			msg = JSON.stringify(p_obj);
		}
		catch (err){
			//return 404 if not exist
			msg = '{"reason": "Promotion with ID '+req.params.pid+' doesn\'t exists"}';
			code = 404;
		}
	}
	else{
		code = 500;
		msg = '{"reason": "Could not connect to database"}';
	}
	res.writeHead(code, {'Content-Type': 'text/plain'});
	res.end(msg);
	return;	
});

app.listen(3000);
console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);
