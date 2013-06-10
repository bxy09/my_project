var current_node_index = 0;
var current_day_index = 0;
var current_log_index = 0;
var current_sar_index = 0;

var current_frame_id = 0;

function reinit_node_day_log_sar(){
	current_frame_id++;
	var day_text = $("#time_display span");
	var node_text = $("#node_display span");
	var sar_text = $("#sar_display span");
	var log_text = $("#log_display span");
	day_text.empty();
	node_text.empty();
	sar_text.empty();
	log_text.empty();

	var date = timestamp_to_monthday(time.start_time+current_day_index*seconds_in_day);
	day_text.append(date.string);
	node_text.append(nodes[current_node_index]);
	var sar_cell = sars[current_sar_index];
	sar_text.append(sar_cell.id1+'.'+sar_cell.id2);
	var log_cell = logs[current_log_index];
	log_text.append(log_cell.db+':'+log_cell.index);
	draw_sar(current_frame_id);
	draw_log(current_frame_id);
}
function load_nodes_abstraction(){

}
var current_select = -1;
var selects = [$("#node_select"),$("#time_select"),$("#sar_select"),$("#log_select")];
$(document).ready(function(){
	$(".head_display span").click(function(){
		var cur_index = $(this).attr('index');
		if(current_select!=-1 && cur_index != current_select){
			selects[current_select].css({'display':'none'});
		} else if(current_select == cur_index) {
			selects[current_select].css({'display':'none'});
			current_select = -1;
			return;
		}
		current_select = cur_index;
		selects[current_select].css({'display':'block'});

	});
	$(".head_display").click(function(e){
		if(e.target == e.currentTarget && current_select >= 0){
			selects[current_select].css({'display':'none'});
			current_select = -1;
		}
	});
	load_nodes();
	load_days();
	load_logs();
	load_sars();
	reinit_node_day_log_sar();
////////////////////////////////
function load_nodes(){
	var str_in_selector = "<tr>";
	var cell_in_line = 10;
	var line_index = 0;
	for(var i = 0; i < nodes.length; i++) {
		if(line_index == cell_in_line) {
			line_index = 0;
			str_in_selector += "</tr><tr>";
		}
		str_in_selector += "<td index="+i+">"+nodes[i]+"</td>";
		line_index ++;
	}
	str_in_selector += '</tr>';
	$("#node_select table").append(str_in_selector);
	$("#node_select td").click(function(){
		current_node_index = $(this).attr('index');
		reinit_node_day_log_sar();
	});
}
function load_days(){
	var str_in_selector = "<tr>";
	var cell_in_line = 10;
	var line_index = 0;
	var last_month = -1;
	for(var i = 0; i<time.days;i++) {
		var date = timestamp_to_monthday(time.start_time+i*seconds_in_day);
		console.warn(last_month);
		if((line_index == cell_in_line)||(last_month != -1 && last_month != date.month)) {
			line_index = 0;
			str_in_selector += "</tr><tr>";
			//if(last_month != date.month)
		}
		last_month = date.month;
		str_in_selector += "<td index="+i+">"+date.string+"</td>";
		line_index ++;
	}
	str_in_selector += '</tr>';
	$("#time_select table").append(str_in_selector);
	$("#time_select td").click(function(){
		current_day_index = $(this).attr('index');
		reinit_node_day_log_sar();
	});
}
function load_logs(){
	var logs_in_selector = "";
	for(var i = 0; i<logs_in.length;i++) {
		for(var j = 0; j<logs_in[i].num;j++) {
			logs_in_selector += "<li index="+logs.length+">"+logs_in[i].db+':'+j
				+"</li>";
			logs.push({db:logs_in[i].db,index:j});
		}
	}
	$("#log_select ul").append(logs_in_selector);
	$("#log_select li").click(function(){
		current_log_index = $(this).attr('index');
		reinit_node_day_log_sar();
	});
}
function load_sars(){
	var sars_in_selector = "";
	for(var i = 0; i<sars.length;i++) {
		sars_in_selector += "<li index="+i+">"+sars[i].id1+'.'+sars[i].id2;
		+"</li>";
	}
	$("#sar_select ul").append(sars_in_selector);
	$("#sar_select li").click(function(){
		current_sar_index = $(this).attr('index');
		reinit_node_day_log_sar();
	});
}
});
jQuery.support.cors = true;
 
var databaseUrl= "http://166.111.69.24:27080";
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
function findAll(db, collection, criteria, fields, sort, for_all_function) {
	var cursor_id;
	var vectors = [];
	jQuery.ajax(databaseUrl + '/' + db+'/'+collection+
		'/_find?'+
		'criteria='+encodeURI(JSON.stringify(criteria))+
		'&fields='+encodeURI(JSON.stringify(fields))+
		'&sort='+encodeURI(JSON.stringify(sort))	, { 
		type: 'get',
		success: function (collections) {
			if(collections.ok != 1) {console.log("can't find!!");return;}
			cursor_id = collections.id;
			if(collections.results.length == 0) {for_all_function(vectors);return;}
			for(var i =0; i < collections.results.length;i++)  {
				vectors.push(collections.results[i]);
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
				if(collections.results.length == 0) {for_all_function(vectors);return;}
				for(var i =0; i < collections.results.length;i++) {
					vectors.push(collections.results[i]);
				}
				more();
			}
		});
	}
}
function timestamp_to_monthday(timestamp){
	var date = new Date((timestamp)*1000);
	var month_name = ['Jan','Feb','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
	return {month:date.getMonth()+1,day:date.getDate(),string:month_name[(date.getMonth()+1)]+' '+date.getDate()};
}