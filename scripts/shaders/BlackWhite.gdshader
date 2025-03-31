shader_type canvas_item;

bool is_white(float average, ivec2 pixel_pos){
	bool pixel_bools[] = {
		(pixel_pos.x)%4==0&&(pixel_pos.y+3)%4==0,
		(pixel_pos.x+2)%4==0&&(pixel_pos.y+1)%4==0,
		(pixel_pos.x+2)%4==0&&(pixel_pos.y+3)%4==0,
		(pixel_pos.x)%4==0&&(pixel_pos.y+1)%4==0,
		(pixel_pos.x+1)%4==0&&(pixel_pos.y+2)%4==0,
		(pixel_pos.x+3)%4==0&&(pixel_pos.y)%4==0,
		(pixel_pos.x+3)%4==0&&(pixel_pos.y+2)%4==0,
		(pixel_pos.x+1)%4==0&&(pixel_pos.y)%4==0,
		(pixel_pos.x+1)%4==0&&(pixel_pos.y+3)%4==0,
		(pixel_pos.x+3)%4==0&&(pixel_pos.y+1)%4==0,
		(pixel_pos.x+3)%4==0&&(pixel_pos.y+3)%4==0,
		(pixel_pos.x+1)%4==0&&(pixel_pos.y+1)%4==0,
		(pixel_pos.x)%4==0&&(pixel_pos.y+2)%4==0,
		(pixel_pos.x+2)%4==0&&(pixel_pos.y)%4==0,
		(pixel_pos.x+2)%4==0&&(pixel_pos.y+2)%4==0,
		true
	};
	bool result = false;
	int max_i = int(average*17.0);
	for (int i = 0; i < max_i; i++){
		result = result||pixel_bools[i];
	}
	return result;
}

void fragment() {
    vec4 cur_pixel = texture(TEXTURE, UV);
	ivec2 pixel_pos = ivec2(UV / TEXTURE_PIXEL_SIZE);
    float average = (cur_pixel.r + cur_pixel.g + cur_pixel.b) / 3.0;
	if(is_white(average, pixel_pos)){
		COLOR = vec4(1.0, 1.0, 1.0, cur_pixel.a);
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, cur_pixel.a);
	}
}