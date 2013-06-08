     
var current_on = {x:-1,y:-1};
var current_e = undefined;
var move_draw_flag = 0;
var block_size = {x:4,y:4};
var c=document.getElementById("myCanvas");
var cProjector=document.getElementById("projector_canvas");
var cxt=c.getContext("2d");
var projector_cxt=cProjector.getContext("2d");
var data;
var statics;
var sub_data_switch = [1,1,1];
var color_thresh_switch = 0;
var projector_value = [];
for(var i = 0; i <11; i++) {
    projector_value[i] = i*0.1;
}
function find_color_index(vector,value) {
    var base = 0;
    var length = vector.length;
    while(length != 1) {
        var target = base + Math.floor(length/2);
        if(value == vector[target]["cover"]) {
            return target;
        } else if(value < vector[target]["cover"]){
            length = base + length - target;
            base = target;
        } else {
            length = target - base;
        }
    }
    return base;
}
function projection_to_color(value,channel_index) {
    if(sub_data_switch[channel_index] == 0) {return 0;}
    if(value == 0) {return 0;}
    var color_channel = 0;
    if(color_thresh_switch){
        color_channel=10*value/statics[channel_index][0]['cover'];
        var index=Math.floor(color_channel);
        if(index>=10){index = 9;}
        color_channel = (color_channel - index)*(projector_value[index+1]-projector_value[index]) + 
        projector_value[index];
        color_channel = Math.floor(color_channel*255);
        
        if(color_channel<0){color_channel = 0;}
        if(color_channel>255){color_channel = 255;}
    } else {
        var division_num = statics[channel_index].length;
        color_channel = 255 - Math.floor(255*find_color_index(statics[channel_index],value)/division_num);
    }
    return color_channel;
}
function draw_canvas(cursor,last_one){
	if(current_e != undefined) {return 0;}
    if(last_one.y >=0 && last_one.y< data[0]["data"].length) {
        upper_layer_cxt.clearRect(0,block_size.y*last_one.y,canvas_width,block_size.y);
        
    }
	if(current_e != undefined) {return 0;}
    if(last_one.x >=0 && last_one.x< data.length) {
        upper_layer_cxt.clearRect(block_size.x*last_one.x,0,block_size.x,canvas_height);
        
    }
	if(current_e != undefined) {return 0;}
    if(cursor.x >= 0 && cursor.y >= 0 && cursor.x < data.length && cursor.y < data[0]["data"].length) {
        upper_layer_cxt.fillStyle = "rgba(247,189,64,0.4)";
        //upper_layer_cxt.clearRect(0,0,canvas_width,canvas_height);
        upper_layer_cxt.fillRect(0,block_size.y*cursor.y,canvas_width,block_size.y);
        upper_layer_cxt.fillRect(block_size.x*cursor.x,0,block_size.x,canvas_height);
		if(move_draw_flag){return 1;}
        for(var k = 0;k < data[cursor.x]["data"][cursor.y].length;k++) {
            if(sub_data_switch[k] == 0) {
                $("#bar"+k+" .sub_data_current_value").text("");
                $("#bar"+k+" .sub_data_displaybar_fron").stop(1,0);
                $("#bar"+k+" .sub_data_displaybar_fron").animate({"width":0},"fast");
            } else {
                $("#bar"+k+" .sub_data_current_value").text(data[cursor.x]["data"][cursor.y][k]);
                $("#bar"+k+" .sub_data_displaybar_fron").stop(1,0);
                $("#bar"+k+" .sub_data_displaybar_fron").animate(
                    {"width":Math.floor(200*data[cursor.x]["data"][cursor.y][k]/statics[k][0]['cover'])},"fast");
            }
        }
    } else {
        for(var k = 0;k < data[0]["data"][0].length;k++) {
            $("#bar"+k+" .sub_data_current_value").text("");
            $("#bar"+k+" .sub_data_displaybar_fron").stop(1,0);
            $("#bar"+k+" .sub_data_displaybar_fron").animate({"width":0},"fast");
        }
    }
    return 1;
}
var last_on = {x:-1,y:-1};
var x=-1;
var y=-1;
var client_pos = {x:-1,y:-1};
var down_count = 10;
function move_draw(){
    if(current_e == -1) {
        current_e = undefined;
		move_draw_flag = 0;
        if(draw_canvas({x:-1,y:-1},current_on)) {
            console.warn(current_on);
			$("#left"+last_on.y).css({"color":"gray"});
			$("#left"+last_on.y).animate({"font-weight":"normal","font-size":"12pt"});
			$("#top"+last_on.x).css({"color":"gray"});
			$("#top"+last_on.x).animate({"font-weight":"normal","font-size":"12pt","width":"60"});
            last_on = {x:-1,y:-1};
            current_on = {x:-1,y:-1};
		}
        return;
    }
    if(current_e == undefined) {
		down_count --;
		if(down_count != 0) {setTimeout('move_draw()',20);return;}
        move_draw_flag = 0;
		draw_canvas(current_on,current_on);
		console.warn()
		var left_y = $("#left"+y);
		left_y.stop(true,false);
		left_y.css({"color":"gold","font-weight":"bold","font-size":"20pt"});
		var top_x = $("#top"+x);
		top_x.stop(true,false);
		top_x.css({"color":"gold","font-weight":"bold","font-size":"20pt","width":"auto"});
        var left_table = $("#left_table");
        left_table.stop(true,true);
        left_table.animate({"marginTop":client_pos.y-$("#canvas").offset().top-10-y*24},"slow");
        var top_table = $("#top_table");
        top_table.stop(true,true);
        top_table.animate({"marginLeft":client_pos.x-$("#canvas").offset().left-x*62});
        if(last_on.y != current_on.y) {
            setTimeout('$("#left"+'+last_on.y+').css({"color":"gray","font-weight":"normal","font-size":"12pt"})',200);
        }
        if(last_on.x != current_on.x) {
            setTimeout('$("#top"+'+last_on.x+').css({"color":"gray","font-weight":"normal","font-size":"12pt","width":"60"})',200);
        }
        last_on=current_on;
        return;
    }
    actual_e = getOffset(current_e);
    x=Math.floor(actual_e.x/block_size.x);
    y=Math.floor(actual_e.y/block_size.y);
	client_pos = {x:current_e.clientX,y:current_e.clientY};
    current_e = undefined;
	down_count = 20;
    if(y != current_on.y || x != current_on.x) {
		if(draw_canvas({x:x,y:y},current_on)) {
			current_on = {x:x,y:y};
		} else {
			console.warn("not draw");
		}
    }
    setTimeout('move_draw()',10);   
} 
function getOffset(evt) {
    return { x: evt.offsetX || evt.layerX, y: evt.offsetY || evt.layerY };
}
function re_draw_all(){
    $("#canvas").fadeIn(200);
    for(var i = 0;i < data.length;i++) {
        var x = block_size.x*i;
        for(var j = 0;j < data[i]["data"].length;j++) {
            var y = block_size.y*j;
            var color = [0,0,0];
            for(var k = 0;k < data[i]["data"][j].length;k++) {
                color[k] = projection_to_color(data[i]["data"][j][k],k);
            }
            cxt.fillStyle = "rgb("+color[0]+","+color[1]+","+color[2]+")";

            cxt.fillRect(x,y,block_size.x-1,block_size.y-1);var color = {r:0,g:0,b:0};
        }
    }
}
var upper_layer_c=document.getElementById("upper_layer");
var upper_layer_cxt=upper_layer_c.getContext("2d");
function init_data_and_canvas(data_index) {
    // /$("#myCanvas").;
    $("#data"+data_index).css({"color":"gold"});
    data = all_data[data_index]["data"];
    statics = all_data[data_index]["statics"];
    c.width = block_size.x*data.length;
    if(c.width != 0) {
        c.height = block_size.y*data[0]["data"].length;
    }
    canvas_width = c.width;
	canvas_height = c.height;
    upper_layer_c.width = canvas_width;
    upper_layer_c.height = canvas_height;  
    var left_table = $("#left_table");
    left_table.empty();
    for(var i = 0;i < yname.length;i++) {
        var new_row = "<tr><td id=left"+i+">"+yname[i]+"</td></tr>";
        left_table.append(new_row);
    }
    var top_row = $("#top_row");
    top_row.empty();
    for(var i = 0;i < data.length;i++) {
        var new_column = "<td><div id=top"+i+">"+data[i]["name"]+"</div></td><";
        top_row.append(new_column);
    }
    var sub_data_table = $("#select_sub_data");
    console.warn(sub_data_table);
    sub_data_table.empty();
    for(var i = 0;i < sub_data_name[data_index].length;i++) {
        var color = [0,0,0];
        color[i] = 255;
        var new_column = "<tr><td><div id=bar"+i+" val="+i+" class=\'sub_data_bar\''>"+
            "<div class=\'sub_data_name\'>"+sub_data_name[data_index][i]+"</div>"+
            "<div class=\'sub_data_current_value\'></div>"+
            "<div class=\'sub_data_displaybar_back\'>"+
            "<div class=sub_data_displaybar_fron style=\'background-color:rgb("+
                color[0]+","+color[1]+","+color[2]+");\' >"+
            "</div></div>"+
            "<div class=\'sub_data_max_value\'>"+all_data[data_index]['statics'][i][0]['cover']+"</div>"+
            "</div></td></tr>";
        console.warn(sub_data_name[data_index][i]);
        sub_data_table.append(new_column);
		color = " gray";
		if(sub_data_switch[i]) {color = " gold"}
		$("#bar"+i+" .sub_data_displaybar_back").css({'background-color':color});
    }
    sub_data_table.append("<div class=color_switch><div class=color_switch_thumb></div></div>");
    $("#containner").fadeIn("slow");
    //setTimeout('re_draw_all()',300);
    set_canvas_size();
    re_draw_all();
    $("#data"+data_index).animate({"font-size":"30pt"},500);

    $(".sub_data_bar").click(function(e){
        var id = $(this).attr("val");
        sub_data_switch[id] = !sub_data_switch[id];
        var color = " gray";

        if(sub_data_switch[id]) {color = " gold"}
        $("#bar"+id+" .sub_data_displaybar_back").css({'background-color':color});
        re_draw_all();
    });
    $(".color_switch").click(function(e){
        color_thresh_switch = !color_thresh_switch;
        if(color_thresh_switch) {
            $("#projector_canvas").fadeIn();
            re_draw_projector();
        } else {
            $("#projector_canvas").fadeOut();
        }
        $(".color_switch_thumb").stop(1,0);
        $(".color_switch_thumb").animate({"margin-left":""+color_thresh_switch*100});
        re_draw_all();
    });
}
function set_canvas_size(){
    var most_width = document.documentElement.clientWidth - 2*100;
    console.warn("clientWidth:"+document.documentElement.clientWidth);
    if(c.width + 20 < most_width){ 
        $("#canvas").css("width",c.width);
        $("#top_panel").css("width",c.width + 100);
    } else {
        $("#canvas").css("width",most_width);
        $("#top_panel").css("width","auto");

    }
    var most_height = document.documentElement.clientHeight - $("#canvas").offset().top -10;
    if(c.height + 20 < most_height){ 
        $("#canvas").css("height","auto");
        $("#left_panel").css("height",c.height + 20);
    } else {
        $("#canvas").css("height",most_height);
        $("#left_panel").css("height",most_height);    
    }
    
}
function re_draw_projector() {
    projector_cxt.fillStyle = "black";
    cProjector.width = cProjector.width;
    var xp = Math.floor(20);
    var yp = Math.floor(120-10-100*projector_value[0]);
    projector_cxt.strokeStyle="red";
    projector_cxt.lineWidth="2";
    projector_cxt.moveTo(xp,yp);
    for(var i = 1; i < projector_value.length; i++) {
        var xp = Math.floor(20+8*i);
        var yp = Math.floor(120-10-100*projector_value[i]);
        projector_cxt.lineTo(xp,yp);
    }
    projector_cxt.stroke();
    projector_cxt.fillStyle = "gold";
    for(var i = 0; i < projector_value.length; i++) {
        var xp = Math.floor(20+8*i);
        var yp = Math.floor(120-10-100*projector_value[i]);
        projector_cxt.fillRect(xp-2,yp-2,5,5);
    }
    
}
    
$(document).ready(function(){
    if(color_thresh_switch) {
        $("#projector_canvas").css({display:'inline'});
    } else {
        $("#projector_canvas").css({display:'none'});
    }
    for(var i = 0; i < all_data.length;i++) {
        var select_data_table = $("#select_data");
        var new_row = "<tr id=data"+i+" val="+i+"><td>"+all_data[i]['data_name']+"</td></tr>";
        select_data_table.append(new_row);
    }

    var current_data_index = 0;
    init_data_and_canvas(current_data_index);
    set_canvas_size();
    re_draw_projector();

    $(window).resize(function(){set_canvas_size();});
    $("#upper_layer").mouseout(function(){
        current_e = -1;
        if(move_draw_flag == 0) {
            move_draw_flag = 1;
            move_draw();
    }
    });
    $("#upper_layer").mousemove(function(e){
        current_e = e;
        if(move_draw_flag == 0) {
            move_draw_flag = 1;
            move_draw();
        }
    });
    $("#select_data tr").click(function(e){
        var new_data_index = $(this).attr("val");
        if(current_data_index != new_data_index) {
            $("#select_data tr").animate({"font-size":"20pt"},200);
            // /$("#myCanvas").;
            $("#select_data tr").css({"color":"gray"});
            current_data_index = new_data_index;
            $("#data"+current_data_index).css({"color":"gold"});
            $("#containner").fadeOut(200);
            setTimeout("init_data_and_canvas("+current_data_index+")",200);
        }
    });
    var current_projector_on = -1;
    $("#projector_canvas").mousedown(function(e){
        //get the index of handle
        var actual_e = getOffset(e);
        if(current_projector_on != -1){alert("logic error of projector mousedown!"+current_projector_on);}
        for(var i = 0; i < projector_value.length; i++) {
            var xr = actual_e.x-Math.floor(20+8*i);
            var yr = actual_e.y-Math.floor(120-10-100*projector_value[i]);
            if(xr*xr+yr*yr<36) {
                current_projector_on = i;
                break;
            }
        }
        console.warn("bb:"+current_projector_on);
    });
    $("#projector_canvas").mousemove(function(e){
        if(current_projector_on != -1) {
            var value = (120-10-getOffset(e).y)/100;
            if(value<0) {value = 0;}
            if(value>1) {value = 1;}
            projector_value[current_projector_on] = value;
            for(var i = 0; i < current_projector_on; i++){
                if(projector_value[i]>value){
                    projector_value[i]=value;
                }
            }
            for(var i = current_projector_on+1; i < projector_value.length; i++){
                if(projector_value[i]<value){
                    projector_value[i]=value;
                }
            }
            re_draw_projector();
        }
    });
    $("#projector_canvas").mouseup(function(e){
        current_projector_on = -1;
        re_draw_all();
    });
    $("#projector_canvas").mouseout(function(e){
        current_projector_on = -1;
        re_draw_all();
    });
});