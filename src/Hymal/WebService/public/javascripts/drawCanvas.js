var canvas_size={width:1000,height:250};
var border_left = 80;
var border_bottom = 20;
var inside_width = 900;
var inside_height = 200;
var log_draw=document.getElementById("log_draw");
var sar_draw=document.getElementById("sar_draw");
var log_context = log_draw.getContext("2d");
var sar_context = sar_draw.getContext("2d");
function position_inside(x,y) {
	x = border_left + x*(inside_width);
	y = canvas_size.height - border_bottom - y*(inside_height);
	return {'x':x,'y':y};
}
function draw_base_line(context,max,min) {
	//draw x
	context.beginPath();
    context.lineWidth="0.2";

    var vertical_val = [0,0.25,0.5,0.75,1];
    //vertical_val.push((min+2max)/3);
    //vertical_val.push((2min+max)/3);
	context.font="10px Arial";
	context.fillStyle = 'rgba(0,0,0,0.5)';
    for(var i = 0; i < vertical_val.length; i++) {
    	var y_pos = position_inside(0,vertical_val[i]).y;
    	var y_val = min+vertical_val[i]*(max-min);
    	y_val = y_val.toPrecision(3);
    	if(max-min<10*min && i != 0){
    		y_val = vertical_val[i]*(max-min);
    		y_val = '+'+y_val.toPrecision(3);
    	}
		context.moveTo(border_left,y_pos);
		context.lineTo(border_left+inside_width,y_pos);
		var width_of_text = context.measureText(y_val).width;
		context.fillText(y_val,border_left - width_of_text -5,
			y_pos + 5);
    }
    for(var i = 0; i < 25; i++) {
    	var x_pos = position_inside(i/24,0).x;
    	var x_val = i;
		context.moveTo(x_pos,canvas_size.height - inside_height - border_bottom);
		context.lineTo(x_pos,canvas_size.height - border_bottom);
		var width_of_text = context.measureText(x_val).width;
		context.fillText(x_val,x_pos - width_of_text/2,
			canvas_size.height - border_bottom + 15);
    }
	
	context.strokeStyle='rgba(0,0,0,1)';
	context.stroke();
}
var seconds_in_day = 3600*24;
function draw_sar(frame_id){
	sar_draw.width = canvas_size.width;
	sar_draw.height = canvas_size.height;
	current_day_index = current_day_index*1;
  findAll('Sar_signal', nodes[current_node_index], 
  	{'logTime':{'$gte':days[current_day_index],
  							'$lte':days[current_day_index] + seconds_in_day},
  	 'tempID':sars[current_sar_index].pos}, 
  	{'logTime':1},{'logTime':1},function(vector){
  		if(current_frame_id != frame_id) {return;}
  		for(var i = 0; i < vector.length; i++) {
		  		var square_width = 10*60/seconds_in_day;
	  			var x = (vector[i]['logTime'] - days[current_day_index])/seconds_in_day;
					sar_context.fillStyle = "rgba(0,189,0,0.5)";
	  			var inside_pos_1 = position_inside(x-square_width/2,1);
	  			var inside_pos_2 = position_inside(x+square_width/2,0);
	  			//sar_context.fillRect(inside_pos_1.x,inside_pos_1.y,
	  			//	inside_pos_2.x-inside_pos_1.x,inside_pos_2.y-inside_pos_1.y);
  		}
  	});
  if(sars[current_sar_index].neg>=0) {
  	findAll('Sar_signal', nodes[current_node_index], 
	  	{'logTime':{'$gte':time.start_time+current_day_index*seconds_in_day,
	  							'$lte':time.start_time+(current_day_index+1)*seconds_in_day},
	  	 'tempID':sars[current_sar_index].neg}, 
	  	{'logTime':1},{'logTime':1},function(vector){
	  		if(current_frame_id != frame_id) {return;}
	  		for(var i = 0; i < vector.length; i++) {
		  		var square_width = 10*60/seconds_in_day;
	  			var x = (vector[i]['logTime'] - time.start_time - current_day_index*seconds_in_day)/seconds_in_day;
					sar_context.fillStyle = "rgba(0,0,189,0.5)";
	  			var inside_pos_1 = position_inside(x-square_width/2,1);
	  			var inside_pos_2 = position_inside(x+square_width/2,0);
	  			sar_context.fillRect(inside_pos_1.x,inside_pos_1.y,
	  				inside_pos_2.x-inside_pos_1.x,inside_pos_2.y-inside_pos_1.y);
	  		}
	  	});
  }
  var line = 'var fields = {\''+sars[current_sar_index].id1+'.'+sars[current_sar_index].id2+'\':1};';
  eval(line);
  findAll('Sar', nodes[current_node_index], 
  	{'_id':{'$gte':days[current_day_index],
  							'$lte':days[current_day_index] + seconds_in_day}},
  		fields,{'_id':1},function(vector){
  			if(current_frame_id != frame_id) {return;}
  			var max = 0;
  			var min = 10000000000000;
  			for(var i = 0; i < vector.length; i++) {
  				var target = vector[i];
	  			if(target[sars[current_sar_index].id1]!=undefined && 
	  				target[sars[current_sar_index].id1][sars[current_sar_index].id2]!=undefined) {
	  				var value = target[sars[current_sar_index].id1][sars[current_sar_index].id2];
	  				if(value > max) {max = value;}
	  				if(value < min) {min = value;}
	  			}else {
	  				min = 0;
	  			}
  			}
  			//if(max == 0) {max = 10;}
        if(min == max) {max += 10;}
  			max = 1*max;min = 1*min;
  			draw_base_line(sar_context,max,min);
  			sar_context.beginPath();
			sar_context.fillStyle = "rgba(247,189,64,0.4)";
    		sar_context.lineWidth="0.5";
			var grd=sar_context.createRadialGradient(5,5,1,7,7,3);
			grd.addColorStop(0,"red");
			grd.addColorStop(1,"rgba(0,0,0,0)");
  			for(var i = 0; i < vector.length; i++) {
  				var target = vector[i];

  				var cur_time = target['_id'];
  				var x = (cur_time - days[current_day_index])/seconds_in_day;
  				var y = 0;
	  			if(target[sars[current_sar_index].id1]!=undefined && 
	  				target[sars[current_sar_index].id1][sars[current_sar_index].id2]!=undefined) {
	  				var value = target[sars[current_sar_index].id1][sars[current_sar_index].id2];
	  				y = (value-min)/(max-min);
	  			}
	  			var inside_pos = position_inside(x,y);
				//sar_context.strokeStyle="red";
	  			if(i==0){
    				sar_context.moveTo(inside_pos.x,inside_pos.y);
    			} else {
    				sar_context.lineTo(inside_pos.x,inside_pos.y);
    			}
    			//sar_context.fillStyle=grd;
					sar_context.fillRect(inside_pos.x-2,inside_pos.y-2,4,4);
  			}
			sar_context.strokeStyle="red";
    		sar_context.stroke();
  	});
}
function draw_log(frame_id){
	log_draw.width = canvas_size.width;
	log_draw.height = canvas_size.height;
	current_day_index = current_day_index*1;
  	var day_time = days[current_day_index];
  findAll('JobAssign', 'JobAssign', 
  	{'eventTime':{'$gte':day_time},
  	 'submitTime':{'$lte':day_time + seconds_in_day},
  	 'startTime':{'$lte':day_time + seconds_in_day},
  	 'execHosts':nodes[current_node_index]}, 
  	{'eventTime':1,'submitTime':1,'startTime':1,'jStatus':1,'exitInfo':1},
  	{'submitTime':1}
  	,function(vector){
  		if(current_frame_id != frame_id) {return;}
  		for(var i = 0; i < vector.length; i++) {
  			var start_time = vector[i]['startTime'];
  			if(start_time < vector[i]['submitTime']) {
  				start_time = submitTime;
  			}
  			var end_time = vector[i]['eventTime'];
  			var runtime = end_time - start_time;
  			if(runtime < 30) {continue;}
  			if(start_time < day_time){start_time = day_time;}
  			if(end_time > day_time+seconds_in_day){end_time = day_time+seconds_in_day;}
  			var x1 = (start_time - day_time)/seconds_in_day;
  			var x2 = (end_time - day_time)/seconds_in_day;
  			var inside_pos_1 = position_inside(x1,1);
  			var inside_pos_2 = position_inside(x2,0);
  			if(vector[i]['jStatus'] == 64){
				  log_context.fillStyle = "rgba(255,0,0,0.5)";
          log_context.fillRect(inside_pos_1.x,inside_pos_1.y,
            inside_pos_2.x-inside_pos_1.x,10);
  			} else if(vector[i]['exitInfo'] == 0){
				  log_context.fillStyle = "rgba(0,0,255,0.5)";
          log_context.fillRect(inside_pos_1.x,inside_pos_1.y+20,
            inside_pos_2.x-inside_pos_1.x,10);
  			} else {
				  log_context.fillStyle = "rgba(0,255,0,0.5)";
          log_context.fillRect(inside_pos_1.x,inside_pos_1.y+10,
            inside_pos_2.x-inside_pos_1.x,10);
  			}
  			
  		}
  	});
 	var log_cell = logs[current_log_index];
	findAll(log_cell.db, nodes[current_node_index], 
  		{'logTime':{'$gte':day_time,
  							'$lte':day_time+seconds_in_day},
  		 'tempID':log_cell.index-0}, 
  		{'logTime':1},{'logTime':1},function(vector){
  			if(current_frame_id != frame_id) {return;}
  			var output_val = [];
  			for(var i =0; i< 24*6;i++) {
  				output_val.push(0);
  			}
  			var max = 10;
  			var min = 10000000;
  			for(var i = 0; i < vector.length; i++) {
  				var log_time = vector[i]['logTime'];
  				var index = (log_time - day_time)/60/10;
  				index = Math.floor(index);
  				output_val[index] ++;
  				console.warn("index:"+index);
  			}
  			//console.warn(output_val);
  			for(var i =0; i< output_val.length;i++) {
  				if(output_val[i] < min) {min = output_val[i];}
  				if(output_val[i] > max) {max = output_val[i];}
  			}
  			max = 1*max;min = 1*min;
  			draw_base_line(log_context,max,min);

  			log_context.beginPath();
			log_context.fillStyle = "rgba(255,255,255,0.4)";
    		log_context.lineWidth="0.5";
			var grd=log_context.createRadialGradient(5,5,1,7,7,3);
			grd.addColorStop(0,"red");
			grd.addColorStop(1,"rgba(0,0,0,0)");
  			for(var i = 0; i < output_val.length; i++) {
  				var value = output_val[i];
  				var x = i/24/6;
  				var y = 0;
	  			y = (value-min)/(max-min);
	  			var inside_pos = position_inside(x,y);
	  			if(i==0){
    				log_context.moveTo(inside_pos.x,inside_pos.y);
    			} else {
    				log_context.lineTo(inside_pos.x,inside_pos.y);
    			}
				log_context.fillRect(inside_pos.x-2,inside_pos.y-2,4,4);
  			}
			log_context.strokeStyle="black";
    		log_context.stroke();
  	});
}
