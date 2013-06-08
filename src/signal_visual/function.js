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
 
var databaseUrl= "http://localhost:9292";
jQuery.ajax(databaseUrl + '/' + 'messages', { 
	type: 'get',
	success: function (collections) {
		console.log(collections);
	}
});
