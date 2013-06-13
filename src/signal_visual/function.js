var current_node_index = 0;
var current_day_index = 0;
var current_log_index = 0;
var current_sar_index = 0;

var current_frame_id = 0;
var nodes_index;
var sig_to_sar_index;
var sig_to_log_index;

function reinit_node_day_log_sar(){
	current_frame_id++;
	console.warn("current_frame_id:"+current_frame_id);
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

function get_function_for_light(light,color){
	light.attr('light_color','black');
	return function(target){
		if(light.length==0){
			console.warn(light);
		}
		light.attr('light_color',color);
	}
}

function start_nodes_all(){
	$("#node_select").find("td[index]").find("#3").attr('light_color','black');
	$("#node_select").find("td[index]").find("#4").attr('light_color','black');
	$("#node_select").find("td[index]").find("#5").attr('light_color','black');
	jQuery.ajax(restUrl +'/nodes_abstract?'+
		'start_time='+encodeURI(time.start_time)+
		'&day_count='+encodeURI(time.days)+
		'&sar_pos='+encodeURI(sars[current_sar_index].pos)+
		'&sar_neg='+encodeURI(sars[current_sar_index].neg)+
		'&log_db='+encodeURI(logs[current_log_index].db)+
		'&log_tempID='+encodeURI(logs[current_log_index].index), { 
		type: 'get',
		success: function (collections) {
			for(var key in collections) {
				var td_cell = $("#node_select").find("td[index='"+nodes_index[key]+"']");
				if(collections[key]['sar']>0){
					td_cell.find('#3').attr('light_color','red');
				}
				if(collections[key]['log']>0){
					td_cell.find('#4').attr('light_color','green');
				}
				if(collections[key]['job']>0){
					td_cell.find('#5').attr('light_color','blue');
				}
			}
		}
	});
	return;
}

function start_nodes(){
	var current_time = current_day_index*seconds_in_day + time.start_time;
	$("#node_select").find("td[index]").find("#0").attr('light_color','black');
	$("#node_select").find("td[index]").find("#1").attr('light_color','black');
	$("#node_select").find("td[index]").find("#2").attr('light_color','black');
	jQuery.ajax(restUrl +'/nodes_abstract?'+
		'start_time='+encodeURI(current_time)+
		'&day_count='+encodeURI(1)+
		'&sar_pos='+encodeURI(sars[current_sar_index].pos)+
		'&sar_neg='+encodeURI(sars[current_sar_index].neg)+
		'&log_db='+encodeURI(logs[current_log_index].db)+
		'&log_tempID='+encodeURI(logs[current_log_index].index), { 
		type: 'get',
		success: function (collections) {
			for(var key in collections) {
				var td_cell = $("#node_select").find("td[index='"+nodes_index[key]+"']");
				if(collections[key]['sar']>0){
					td_cell.find('#0').attr('light_color','red');
				}
				if(collections[key]['log']>0){
					td_cell.find('#1').attr('light_color','green');
				}
				if(collections[key]['job']>0){
					td_cell.find('#2').attr('light_color','blue');
				}
			}
		}
	});
	return;
}

function load_days_abstraction() {
	$("#time_select").find("td[index]").find("#0").attr('light_color','black');
	$("#time_select").find("td[index]").find("#1").attr('light_color','black');
	$("#time_select").find("td[index]").find("#2").attr('light_color','black');
	jQuery.ajax(restUrl +'/days_abstract?'+
		'start_time='+encodeURI(time.start_time)+
		'&day_count='+encodeURI(31)+
		'&sar_pos='+encodeURI(sars[current_sar_index].pos)+
		'&sar_neg='+encodeURI(sars[current_sar_index].neg)+
		'&log_db='+encodeURI(logs[current_log_index].db)+
		'&node='+encodeURI(nodes[current_node_index])+
		'&log_tempID='+encodeURI(logs[current_log_index].index), { 
		type: 'get',
		success: function (collections) {
			for(var i = 0; i<collections.length;i++) {
				var td_cell = $("#time_select").find("td[index='"+i+"']");
				if(collections[i]['sar']>0){
					td_cell.find('#0').attr('light_color','red');
				}
				if(collections[i]['log']>0){
					td_cell.find('#1').attr('light_color','green');
				}
				if(collections[i]['job']>0){
					td_cell.find('#2').attr('light_color','blue');
				}
			}
		}
	});
	return;
}
function load_sars_abstraction() {
	var current_time = current_day_index*seconds_in_day + time.start_time;
	$("#sar_select").find("span[index]").css('color',' #ddd');
	jQuery.ajax(restUrl +'/sar_abstract?'+
		'time='+encodeURI(current_time)+
		'&node='+encodeURI(nodes[current_node_index]), { 
		type: 'get',
		success: function (collections) {
			for(var i = 0; i<collections.length;i++) {
				if(collections[i]>0) {
					$("#sar_select").find("span[index='"+sig_to_sar_index[i]+"']")
						.css('color','rgb(199,187,58)');
				}
			}
		}
	});
	return;
}
function load_logs_abstraction() {
	var current_time = current_day_index*seconds_in_day + time.start_time;
	$("#log_select").find("td[index]").css('color',' #ddd');
	jQuery.ajax(restUrl +'/log_abstract?'+
		'time='+encodeURI(current_time)+
		'&node='+encodeURI(nodes[current_node_index]), { 
		type: 'get',
		success: function (collections) {
			for(var key in collections) {
				if(collections[key]<=0) continue;
				$("#log_select").find("td[index='"+sig_to_log_index[key]+"']")
						.css('color','rgb(199,187,58)');
			}
		}
	});
	return;
}
var current_select = -1;
var selects = [$("#node_select"),$("#time_select"),$("#sar_select"),$("#log_select")];
var selects_cursor_pos = [85,235,535,885];
$(document).ready(function(){
	$(".head_display span").click(function(){
		var cur_index = $(this).attr('index');
		if(current_select!=-1 && cur_index != current_select){
			selects[current_select].fadeOut();
		} else if(current_select == cur_index) {
			selects[current_select].fadeOut();
			$("#head_select").animate({'height':0,'paddingTop':0,'paddingBottom':0});
			$(".cursor_rail").animate({'height':0});
			current_select = -1;
			return;
		}
		selects[cur_index].fadeIn();
		var height = selects[cur_index].outerHeight();
		if(height > 500){height=500;}
		$("#head_select").animate({'height':height,'paddingTop':20,'paddingBottom':20});
		$(".cursor_rail").animate({'height':20});
		if(current_select == -1) {
			$(".cursor").css({'marginLeft':selects_cursor_pos[cur_index]});
		} else {
			$(".cursor").animate({'marginLeft':selects_cursor_pos[cur_index]});
		}
		current_select = cur_index;
	});
	$(".head_display").click(function(e){
		if(e.target == e.currentTarget && current_select >= 0){
			selects[current_select].fadeOut();
		$("#head_select").animate({'height':0,'paddingTop':0,'paddingBottom':0});
		$(".cursor_rail").animate({'height':0});
			current_select = -1;
		}
	});
	load_nodes();
	load_days();
	load_logs();
	load_sars();
	reinit_node_day_log_sar();
	load_days_abstraction();
	load_logs_abstraction();
	load_sars_abstraction();
	setTimeout('start_nodes()',20);
	setTimeout('start_nodes_all()',20);
////////////////////////////////
function add_light_group(row_num){
	var str = "<div class='light_group'>";
	for(var i=0;i<row_num*3;i++){
		str+="<div class='light' id="+i+" light_color='black'></div>";
	}
	str += "</div>";
	return str;
}
function load_nodes(){
	var str_in_selector = "<tr>";
	nodes_index = new Object();
	var cell_in_line = 10;
	var line_index = 0;
	for(var i = 0; i < nodes.length; i++) {
		nodes_index[nodes[i]] = i;
		if(line_index == cell_in_line) {
			line_index = 0;
			str_in_selector += "</tr><tr>";
		}
		str_in_selector += "<td index="+i+">"+add_light_group(2)+"<span>"+nodes[i]+"</span></td>";
		line_index ++;
	}
	str_in_selector += '</tr>';
	$("#node_select table").append(str_in_selector);
	$('#node_select td[index='+current_node_index+']').css({"background-color":"rgb(80,80,80)"});
	$("#node_select td").click(function(){
		if(current_node_index == $(this).attr('index')) {return;}
		$('#node_select td[index='+current_node_index+']').css({"background-color":"transparent"});
		$(this).css({"background-color":"rgb(80,80,80)"});
		current_node_index = $(this).attr('index');
		load_days_abstraction();
		load_sars_abstraction();
		load_logs_abstraction();
		reinit_node_day_log_sar();
	});
}
function load_days(){
	var str_in_selector = "";
	var cell_in_line = 20;
	var line_index = 0;
	var last_month = -1;
	for(var i = 0; i<time.days;i++) {
		var date = timestamp_to_monthday(time.start_time+i*seconds_in_day);
		if((line_index == cell_in_line)||(last_month != date.month)) {
			line_index = 0;
			if(last_month != -1) {
				str_in_selector += "</tr>"
			}
			if(last_month!=date.month) {
				str_in_selector += "<tr class='separator'><td colspan=10>"+month_name[date.month-1]+"</td></tr>";
			}
			str_in_selector += "<tr>";
		}
		last_month = date.month;
		str_in_selector += "<td index="+i+">"+add_light_group(1)+date.day+"</td>";
		line_index ++;
	}
	str_in_selector += '</tr>';
	$("#time_select table").append(str_in_selector);
	$('#time_select td[index='+current_day_index+']').css({"background-color":"rgb(80,80,80)"});
	$("#time_select td[index]").click(function(){
		if(current_day_index == $(this).attr('index')) {return;}
		$('#time_select td[index='+current_day_index+']').css({"background-color":"transparent"});
		$(this).css({"background-color":"rgb(80,80,80)"});
		current_day_index = $(this).attr('index');
		reinit_node_day_log_sar();
		load_sars_abstraction();
		load_logs_abstraction();
		setTimeout('start_nodes()',20);
	});
}
function load_logs(){
	var str_in_selector = "";
	var cell_in_line = 20;
	var line_index = 0;
	sig_to_log_index = new Object();
	for(var i = 0; i<logs_in.length;i++) {
		str_in_selector += "<tr class='separator'><td colspan=10>"+logs_in[i].db+"</td></tr><tr>";
		line_index = 0;
		for(var j = 0; j<logs_in[i].num;j++) {
			if(line_index == cell_in_line) {
				str_in_selector += "</tr><tr>";
			}
			str_in_selector += "<td index="+logs.length+">"+j
				+"</td>";
			line_index ++;
			sig_to_log_index[""+logs_in[i].db+" "+j] = logs.length;
			logs.push({db:logs_in[i].db,index:j});
		}
		str_in_selector += '</tr>';
	}
	$("#log_select table").append(str_in_selector);
	$('#log_select td[index='+current_log_index+']').css({"background-color":"rgb(80,80,80)"});
	$("#log_select td[index]").click(function(){
		if(current_log_index == $(this).attr('index')) {return;}
		$('#log_select td[index='+current_log_index+']').css({"background-color":"transparent"});
		$(this).css({"background-color":"rgb(80,80,80)"});
		current_log_index = $(this).attr('index');
		reinit_node_day_log_sar();
		setTimeout('start_nodes()',20);
		setTimeout('start_nodes_all()',20);
		load_days_abstraction();
	});
}
function load_sars(){
	var str_in_selector = "";
	var last_id1 = '';
	sig_to_sar_index = new Object();
	for(var i = 0; i<sars.length;i++) {
		if(last_id1!=sars[i].id1) {
			if(last_id1 != ''){str_in_selector+="</div>"}
			str_in_selector += "<div class='cell'><div class='separator'>"+sars[i].id1+"</div>";
		}
		sig_to_sar_index[sars[i].pos] = i;
		if(sars[i].neg>=0){
			sig_to_sar_index[sars[i].neg] = i;
		}
		last_id1 = sars[i].id1;
		str_in_selector += "<span index="+i+">"+sars[i].id2+"</span>";
	}
	$("#sar_select").append(str_in_selector);
	$('#sar_select span[index='+current_sar_index+']').css({"background-color":"rgb(80,80,80)"});
	$("#sar_select span[index]").click(function(){
		if(current_sar_index == $(this).attr('index')) {return;}
		$('#sar_select span[index='+current_sar_index+']').css({"background-color":"transparent"});
		$(this).css({"background-color":"rgb(80,80,80)"});
		current_sar_index = $(this).attr('index');
		reinit_node_day_log_sar();
		setTimeout('start_nodes()',20);
		setTimeout('start_nodes_all()',20);
		load_days_abstraction();
	});
}
});
jQuery.support.cors = true;
 
var databaseUrl= "http://166.111.69.24:27080";
var restUrl= "http://166.111.69.24:3000";
///////////////////////////////////////////////////////////////////////
//MongoDB
function findOne(db, collection, criteria,foreach_function) {
	var cursor_id;
	jQuery.ajax(databaseUrl + '/' + db+'/'+collection+
		'/_find?'+
		'criteria='+encodeURI(JSON.stringify(criteria))+
		'&limit=1', { 
		type: 'get',
		success: function (collections) {
			if(collections.ok != 1) {
				console.warn("try again!!");
				findOne(db, collection, criteria,foreach_function);
				return;
			}
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
var month_name = ['Jan','Feb','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
function timestamp_to_monthday(timestamp){
	var date = new Date((timestamp)*1000);
	return {month:date.getMonth()+1,day:date.getDate(),string:month_name[(date.getMonth())]+' '+date.getDate()};
}
function if_sar_exist(day,node,sar_index,if_function){
	var day_time = time.start_time+day*seconds_in_day;
	if(day == -1) {
		findOne('Sar_signal', node,
	  	 {'tempID':{'$in':[sars[sar_index].neg,sars[sar_index].pos]}},if_function);
	}else{
		findOne('Sar_signal', node,
			{'logTime':{'$gte':day_time,'$lte':day_time+seconds_in_day},
	  	 'tempID':{'$in':[sars[sar_index].neg,sars[sar_index].pos]}},if_function);
	}
}
function if_log_exist(day,node,log_index,if_function){
	var day_time = time.start_time+day*seconds_in_day;
 	var log_cell = logs[log_index];
	if(day == -1) {
		findOne(log_cell.db, node, 
  		{'tempID':log_cell.index},if_function);
	}else{
		findOne(log_cell.db, node, 
  		{'logTime':{'$gte':day_time,'$lte':day_time+seconds_in_day},
  		'tempID':log_cell.index},if_function);
	}
}
function if_job_exist(day,node,if_function){
	var day_time = time.start_time+day*seconds_in_day
	if(day == -1) {
		findOne('JobAssign', 'JobAssign', 
  	{'eventTime':{'$gte':time.start_time},
  	 'execHosts':node},if_function);
	}else{
		findOne('JobAssign', 'JobAssign', 
  	{'eventTime':{'$gte':day_time},
  	 'submitTime':{'$lte':day_time+seconds_in_day},
  	 'startTime':{'$lte':day_time+seconds_in_day},
  	 'execHosts':node},if_function);
	}
}