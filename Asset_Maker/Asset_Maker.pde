int DRAW_GRID_RESOLUTION = 47;
int ALIGNMENT_SPACING = 8;

float DRAW_GRID_SIZE;
float POINT_SIZE;
float LINE_SIZE;

int SCALING_GRID_RESOLUTION = 32;
float SCALING_GRID_SIZE;
float SCALING_FACTOR;

ArrayList<Point> points = new ArrayList<Point>();
Point currentPoint = new Point(0, 0);

PImage img;

final int DRAW_MODE = 0;
final int SCALE_MODE = 1;

int state = DRAW_MODE;

void setup() {
    size(760, 760);
    
    fill(255, 0, 0);
    rectMode(CENTER);

    points.add(currentPoint);
    
    DRAW_GRID_SIZE  = min(((float)width / DRAW_GRID_RESOLUTION), ((float)height / DRAW_GRID_RESOLUTION));
    SCALING_GRID_SIZE  = min(((float)width / SCALING_GRID_RESOLUTION), ((float)height / SCALING_GRID_RESOLUTION));
    POINT_SIZE = DRAW_GRID_SIZE * 0.8;
    LINE_SIZE  = DRAW_GRID_SIZE * 0.4;
    
    img = loadImage("UF Logo.png");
    if (img.width > img.height) {
        img.resize(width, 0);
    } else {
        img.resize(0, height);
    }
}


void draw() {
    background(0);

    if (state == DRAW_MODE) {
        drawMode();
    } else if (state == SCALE_MODE) {
        scaleMode();
    }
}


void drawMode() {
    tint(51);
    image(img, 0, 0);

    // Update currentPoint to mouse position
    currentPoint.x = canvasToGrid(mouseX);
    currentPoint.y = canvasToGrid(mouseY);
    
    // Draw grid lines
    stroke(150);
    for (int i = 0; i < DRAW_GRID_RESOLUTION; i++) {

        if((i - DRAW_GRID_RESOLUTION/2) % ALIGNMENT_SPACING == 0 || (i - DRAW_GRID_RESOLUTION/2 - 1) % ALIGNMENT_SPACING == 0) {
            strokeWeight(1);
        } else {
            strokeWeight(0.2);
        }

        int offset = (int)((i) * DRAW_GRID_SIZE);
        line(offset, 0,   offset, height);
        line(0, offset,   width, offset);
    }

    // Draw circles and lines connecting them
    for (int i = 0; i < points.size(); i++) {
        Point current = points.get(i);
        noStroke();
        circle(
            gridToDrawCanvas(current.x),
            gridToDrawCanvas(current.y),
            POINT_SIZE
        );
        
        stroke(255, 0, 0);
        strokeWeight(DRAW_GRID_SIZE * 0.3);

        if(i == 0)
            continue;

        Point previous = points.get(i-1);
        if (previous.laser_en) {
            line(
                gridToDrawCanvas(current.x), 
                gridToDrawCanvas(current.y), 
                gridToDrawCanvas(previous.x), 
                gridToDrawCanvas(previous.y)
            );
        }
    }
}


void scaleMode() {
    // Draw grid lines
    stroke(150);
    strokeWeight(0.2);
    for (int i = 0; i < SCALING_GRID_RESOLUTION; i++) {
        int offset = (int)((i) * SCALING_GRID_SIZE);
        line(offset, 0,   offset, height);
        line(0, offset,   width, offset);
    }

    // Draw shape
    stroke(255, 0, 0);
    strokeWeight(floor(SCALING_FACTOR * 0.2 + 1));
    for (int i = 1; i < points.size()-1; i++) {
        Point current = points.get(i);
        Point previous = points.get(i-1);

        if (previous.laser_en) {
            line(
                gridToScaleCanvas(current.x)  + mouseX,
                gridToScaleCanvas(current.y)  + mouseY,
                gridToScaleCanvas(previous.x) + mouseX,
                gridToScaleCanvas(previous.y) + mouseY
            );
        }
    }
}


void mousePressed() {
    if (mouseButton == LEFT) {
        leftClick();
    } else if (mouseButton == RIGHT) {
        rightClick();
    }
}


void leftClick() {
    currentPoint = new Point(0, 0);
    points.add(currentPoint);
}


void rightClick() {
    int col = canvasToGrid(mouseX);
    int row = canvasToGrid(mouseY);

    for (int i = points.size()-2; i >= 0; i--) {
        if (points.get(i).x == col && points.get(i).y == row) {
            points.remove(i);
            return;
        }
    }
}


void keyPressed() {
    if (state == DRAW_MODE) {
        if (key == CODED) {
            if (keyCode == UP) {
                for (int i = 0; i < points.size(); i++)
                    points.get(i).y--;
                return;
            }
            if (keyCode == DOWN) {
                for (int i = 0; i < points.size(); i++)
                    points.get(i).y++;
                return;
            }
            if (keyCode == LEFT) {
                for (int i = 0; i < points.size(); i++)
                    points.get(i).x--;
                return;
            }
            if (keyCode == RIGHT) {
                for (int i = 0; i < points.size(); i++)
                    points.get(i).x++;
                return;
            }

            println(keyCode);

        } else {
            if (key == ' ') {
                if (points.size() > 1)
                    points.get(points.size()-2).laser_en ^= true;  // toggle laser_en
                return;
            }
            if (key == ENTER) {
                SCALING_FACTOR = DRAW_GRID_RESOLUTION / 4096.0 * 50.0;
                state = SCALE_MODE;
                println("Switching to Scaling Mode");
                return;
            }

            println(key);

        }
    }

    else if (state == SCALE_MODE) {
        if (key == CODED) {
            if (keyCode == UP) {
                SCALING_FACTOR *= 1.1;
                return;
            }
            if (keyCode == DOWN) {
                SCALING_FACTOR /= 1.1;
                return;
            }

            println(keyCode);

        } else {
            if (key == ENTER) {
                println("Writing LUT to File");
                writeToFile();
                state = DRAW_MODE;
                return;
            }

            println(key);

        }
    }
    
}


int canvasToGrid(int coord) {
    return floor(coord / DRAW_GRID_SIZE);
}


float gridToDrawCanvas(int coord) {
    return (coord + 0.5) * DRAW_GRID_SIZE;
}


float gridToScaleCanvas(int coord) {
    return ((coord - DRAW_GRID_RESOLUTION*0.5) * SCALING_FACTOR);
}


void writeToFile() {
    PrintWriter fileX = createWriter("lut_x.txt");
    PrintWriter fileY = createWriter("lut_y.txt");

    for (int i = 0; i < points.size()-2; i++) {
        int x = round((gridToScaleCanvas(points.get(i).x)  + mouseX) * 4096.0 / width);
        int y = round((gridToScaleCanvas(points.get(i).y)  + mouseY) * 4096.0 / width);

        fileX.printf("rom[%d] = 12'd%d;\n", i, x);
        fileY.printf("rom[%d] = 12'd%d;\n", i, y);
    }

    fileX.flush();
    fileY.flush();

    fileX.close();
    fileY.close();
}
