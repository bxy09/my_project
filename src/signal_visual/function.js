var current_node_index = 0;
var current_day_index = 0;
var current_log_index = 0;
var current_sar_index = 0;
function draw_sar(){}
function draw_log(){}
function reinit_node_day_log_sar(){
	draw_sar();
	draw_log();
}
$(document).ready(function(){
	reinit_node_day_log_sar();
	load_nodes();
	load_days();
	load_logs();
	load_sars();
function load_nodes(){
}
function load_days(){
}
function load_logs(){
}
function load_sars(){
}
});
jQuery.support.cors = true;
 
var databaseUrl= "http://192.168.1.100:27080";

findOne('messages', 'c01b09', {}, {'logTime':1},{'logTime':1},function(target){console.log(target);});
///////////////////////////////////////////////////////////////////////
//MongoDB
function findOne(db, collection, criteria, fields, sort, foreach_function) {
	var cursor_id;
	jQuery.ajax(databaseUrl + '/' + db+'/'+collection+
		'/_find?'+
		'criteria='+encodeURI(JSON.stringify(criteria))+
		'&fields='+encodeURI(JSON.stringify(fields))+
		'&limit=1'+
		'&sort='+encodeURI(JSON.stringify(sort))	, { 
		type: 'get',
		success: function (collections) {
			if(collections.ok != 1) {console.log("can't find!!");return;}
			cursor_id = collections.id;
			if(collections.results.length == 0) {return;}
			for(var i =0; i < collections.results.length;i++)  {
				foreach_function(collections.results[i]);
			}
		}
	});
}
function findAll(db, collection, criteria, fields, sort, foreach_function) {
	var cursor_id;
	jQuery.ajax(databaseUrl + '/' + db+'/'+collection+
		'/_find?'+
		'criteria='+encodeURI(JSON.stringify(criteria))+
		'&fields='+encodeURI(JSON.stringify(fields))+
		'&sort='+encodeURI(JSON.stringify(sort))	, { 
		type: 'get',
		success: function (collections) {
			if(collections.ok != 1) {console.log("can't find!!");return;}
			cursor_id = collections.id;
			if(collections.results.length == 0) {return;}
			for(var i =0; i < collections.results.length;i++)  {
				foreach_function(collections.results[i]);
			}
			more();
		}
	});
	function more() {
		jQuery.ajax(databaseUrl + '/' + db+'/'+collection+
			'/_more?'+
			'id='+cursor_id, { 
			type: 'get',
			success: function (collections) {
				if(collections.ok != 1) {console.log("can't find!!");return;}
				var cursor_id = collections.id;
				if(collections.results.length == 0) {return;}
				for(var i =0; i < collections.results.length;i++) {
					foreach_function(collections.results[i]);
				}
				more();
			}
		});
	}
}