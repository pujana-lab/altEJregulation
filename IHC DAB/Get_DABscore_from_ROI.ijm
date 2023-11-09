
n = 100 // Number of rectangles

path = File.openDialog("Select a File");
dir = File.getParent(path);
name = File.getName(path);
open(path);

run("Select All");
run("Duplicate...", "title=duplicated");
selectImage(name);

//print(dir);

img_x = getWidth();
img_y = getHeight();

setTool("rotrect");
waitForUser("Draw a rectangle");

getSelectionCoordinates(x, y);

width = sqrt(pow(x[0]-x[1],2) + pow(y[0]-y[1],2))
height = sqrt(pow(x[1]-x[2],2) + pow(y[1]-y[2],2))

if(y[0] <= y[1] && y[0] <= y[2] && y[0] <= y[3]){
		style = "DownRight";
}

if(y[1] <= y[0] && y[1] <= y[2] && y[1] <= y[3]){
		style = "UpLeft";
}

if(y[2] <= y[0] && y[2] <= y[1] && y[2] <= y[3]){
		style = "UpRight";
}

if(y[3] <= y[0] && y[3] <= y[1] && y[3] <= y[2]){
		style = "DownLeft";
}

subangle =(y[1]-y[0])/(x[1]-x[0]);
angle = atan(subangle);

b1 = sin(angle)*height*0.5;
a1 = cos(angle)*height*0.5;

a2 = cos(angle)*width*0.5/n;
b2 = sin(angle)*width*0.5/n;
a2_init = a2;
b2_init = b2;

roiManager("Add");
Overlay.addSelection;
//So we just 'slide' by width/n where n is the number of rectangles
wait(10);
for (i = 1; i <= n; i++) {
	if(style == "DownRight"){
		makeRotatedRectangle(x[0]+a2, y[0]+b2, x[3]+a2, y[3]+b2, width/n);	
	}
	if(style == "UpRight"){
		makeRotatedRectangle(x[0]+a2, y[0]+b2, x[3]+a2, y[3]+b2, width/n);	
	}
	if(style == "UpLeft"){
		makeRotatedRectangle(x[0]-a2, y[0]-b2, x[3]-a2, y[3]-b2, width/n);	
	}
	if(style == "DownLeft"){
		makeRotatedRectangle(x[0]-a2, y[0]-b2, x[3]-a2, y[3]-b2, width/n);	
	}
	
	a2 = a2 + a2_init *2;
	b2 = b2 + b2_init *2;
	wait(10);
	roiManager("Add");
	Overlay.addSelection;
	}

run("Subtract Background...", "rolling=50 light create disable");
run("Colour Deconvolution", "vectors=[H DAB]");
selectImage(name + "-(Colour_3)");
close();
selectImage(name + "-(Colour_1)");
close();
selectImage(name + "-(Colour_2)");
roiManager("Show All");
wait(1000);
run("8-bit");

table1 = "Mildine";
Table.create(table1);
for(i = 1; i < n; i++) {
	roiManager("Select", i);
	Roi.getContainedPoints(xpoints, ypoints);
	grey_0 = 0;
	for(j = 0; j < lengthOf(xpoints); j++){
		grey = getPixel(xpoints[j], ypoints[j]);
		grey_0 = grey_0 + grey;
		colname = "Column" + i;
		Table.set(colname, j, grey);
	}
	Table.update;
	grey_avg = grey_0 / lengthOf(xpoints);
}

z = 1;
save_path = path + "_dab" + z + ".txt";
while( File.exists(save_path)){
	z = z + 1;
	save_path = path + "_dab_" + z + ".txt";
}

Table.save(save_path);
Table.reset(table1);

gangle = Math.toDegrees(angle);
selectImage("duplicated");
run("Select None");
if (gangle<0){
	ggangle = abs(gangle);
	if(style == "DownLeft"){
		ggangle = ggangle + 180;
	} 
	if(style == "UpRight"){
		ggangle = ggangle;
	} 
	run("Rotate... ", "angle=" + ggangle + " interpolation=Bilinear");
	RoiManager.select(0);
	run("Rotate...", "rotate angle=" + ggangle);
} else {
	if(style == "UpLeft"){
		gangle = gangle + 180;
	} 
	print(style);
	print(angle);
	print(gangle);
	
	run("Rotate... ", "angle=-" + gangle + " interpolation=Bilinear");
	RoiManager.select(0);
	run("Rotate...", "rotate angle=-" + gangle);
}

roiManager("Add");
Overlay.addSelection;
RoiManager.select(n+1);
run("Crop");
Overlay.hide
newpath = path + "selArea_" + z + ".png";
print(newpath);
saveAs("png", newpath);

if (isOpen("Log")) {
	selectWindow("Log");
    run("Close" );
}

if (isOpen("Colour Deconvolution")) {
	selectWindow("Colour Deconvolution");
    run("Close" );
}

if (isOpen("Colour Deconvolution")) {
	selectWindow("Colour Deconvolution");
    run("Close" );
}

if (isOpen("Mildine")) {
	selectWindow("Mildine");
    run("Close" );
}

if (isOpen("ROI Manager")) {
	selectWindow("ROI Manager");
    run("Close" );
}

selectImage(name + "-(Colour_2)");
close();
selectImage(name);
close();
selectImage(newpath);
close();
selectImage("duplicated");
close();


