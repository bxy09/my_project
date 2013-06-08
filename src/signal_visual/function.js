var current_node_index = 0;
var current_day_index = 0;
var current_log_index = 0;
var current_sar_index = 0;
var log_draw=document.getElementById("log_draw");
var sar_draw=document.getElementById("sar_draw");
var log_context = log_draw.getContext("2d");
var sar_context = sar_draw.getContext("2d");
var canvas_size={width:1000,height:200};
function draw_sar(){
	sar_draw.width = canvas_size.width;
	sar_context.fillStyle = "rgba(0,189,0,0.8)";
  sar_context.fillRect(0,0,300,300);
  findAll('Sar_signal', nodes[current_node_index], 
  	{'logTime':{'$gte':time.start_time+current_day_index*seconds_in_day,
  							'$lte':time.start_time+(current_day_index+1)*seconds_in_day},
  	 'tempID':sars[current_sar_index].pos}, 
  	{'logTime':1},{'logTime':1},function(vector){
  		for(var i = 1; i < vector.length; i++) {
  			var square_width = 10*60/seconds_in_day*canvas_size.width;
  			console.warn(vector[i]);
  			var x = (vector[i]['logTime'] - time.start_time - current_day_index*seconds_in_day)/seconds_in_day*canvas_size.width;
  			sar_context.fillRect(x-square_width/2,0,square_width,300);
  		}
  	});
  if(sars[current_sar_index].pos>=0) {
  	findAll('Sar_signal', nodes[current_node_index], 
	  	{'logTime':{'$gte':time.start_time+current_day_index*seconds_in_day,
	  							'$lte':time.start_time+(current_day_index+1)*seconds_in_day},
	  	 'tempID':sars[current_sar_index].neg}, 
	  	{'logTime':1},{'logTime':1},function(vector){
	  	});
  }
  var line = 'var fields = {\''+sars[current_sar_index].id1+'.'+sars[current_sar_index].id2+'\':1};';
  console.warn(line);
  eval(line);
  findAll('Sar', nodes[current_node_index], 
  	{'_id':{'$gte':time.start_time+current_day_index*seconds_in_day,
  							'$lte':time.start_time+(current_day_index+1)*seconds_in_day}}, 
  		fields,{'_id':1},function(vector){
  			var max = 0;
  			for(var i = 0; i < vector.length; i++) {
  				var target = vector[i];
	  			if(target[sars[current_sar_index].id1]!=undefined && 
	  				target[sars[current_sar_index].id1][sars[current_sar_index].id2]!=undefined) {
	  				var value = target[sars[current_sar_index].id1][sars[current_sar_index].id2];
	  				if(value > max) {max = value;}
	  			}
  			}
  			console.warn("max："+max);
  			if(max == 0) {max = 10;}
				sar_context.fillStyle = "rgba(247,189,64,0.4)";
				sar_context.strokeStyle="red";
    		sar_context.lineWidth="1";
  			for(var i = 0; i < vector.length; i++) {
  				var target = vector[i];

  				var cur_time = target['_id'];
  				var x = (cur_time - time.start_time - current_day_index*seconds_in_day)/seconds_in_day*canvas_size.width;
  				var y = 0;
	  			if(target[sars[current_sar_index].id1]!=undefined && 
	  				target[sars[current_sar_index].id1][sars[current_sar_index].id2]!=undefined) {
	  				var value = target[sars[current_sar_index].id1][sars[current_sar_index].id2];
	  				var y = value/max*(canvas_size.height-1);
  					
	  			}
	  			if(i==0){
    				sar_context.moveTo(x,canvas_size.height-1-y);
    			} else {
    				sar_context.lineTo(x,canvas_size.height-1-y);
    			}
    			sar_context.stroke();
  			}
  	});
}
function draw_log(){
	sar_context.clearRect(0,0,canvas_size.width,canvas_size.height);
	log_context.fillStyle = "rgba(0,189,64,0.4)";
  log_context.fillRect(0,0,300,300);
}
function reinit_node_day_log_sar(){
	var day_text = $("#time_display");
	var node_text = $("#node_display");
	var sar_text = $("#sar_display");
	var log_text = $("#log_display");
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
	draw_sar();
	draw_log();
}
$(document).ready(function(){
	$("#time_display").click(function(){
		$("#time_select").slideToggle();
	});
	$("#node_display").click(function(){
		$("#node_select").slideToggle();
	});
	$("#log_display").click(function(){
		$("#log_select").slideToggle();
	});
	$("#sar_display").click(function(){
		$("#sar_select").slideToggle();
	});
	load_nodes();
	load_days();
	load_logs();
	load_sars();
	reinit_node_day_log_sar();
////////////////////////////////
function load_nodes(){
	var nodes_in_selector = "";
	for(var i = 0; i < nodes.length; i++) {
		nodes_in_selector += "<li index="+i+">"+nodes[i]+"</li>";
	}
	$("#node_select ul").append(nodes_in_selector);
	$("#node_select li").click(function(){
		current_node_index = $(this).attr('index');
		reinit_node_day_log_sar();
	});
}
function load_days(){
	var days_in_selector = "";
	for(var i = 0; i<time.days;i++) {
		var date = timestamp_to_monthday(time.start_time+i*seconds_in_day);
		days_in_selector += "<li index="+i+">"+date.string
		+"</li>";
	}
	$("#time_select ul").append(days_in_selector);
	$("#time_select li").click(function(){
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
 
var databaseUrl= "http://192.168.1.100:27080";
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
	return {month:date.getMonth()+1,day:date.getDate(),string:(date.getMonth()+1)+'/'+date.getDate()};
}