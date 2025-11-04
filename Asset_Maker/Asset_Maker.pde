
int GRID_RESOLUTION = 31;
int ALIGNMENT_SPACING = 7;

float GRID_SIZE;
float POINT_SIZE;
float LINE_SIZE;

ArrayList<Point> points = new ArrayList<Point>();
Point currentPoint = new Point(0, 0);

PImage img;

void setup() {
    size(760, 760);
    
    fill(255, 0, 0);
    rectMode(CENTER);

    points.add(currentPoint);
    
    GRID_SIZE  = min(((float)width / GRID_RESOLUTION), ((float)height / GRID_RESOLUTION));
    POINT_SIZE = GRID_SIZE * 0.8;
    LINE_SIZE  = GRID_SIZE * 0.4;
    
    img = loadImage("UF Logo.png");
    if (img.width > img.height) {
        img.resize(width, 0);
    } else {
        img.resize(0, height);
    }
}


void draw() {
    background(0);
    tint(51);
    image(img, 0, 0);

    // Update currentPoint to mouse position
    currentPoint.x = canvasToGrid(mouseX);
    currentPoint.y = canvasToGrid(mouseY);
    
    // Draw grid lines
    stroke(150);
    for (int i = 0; i < GRID_RESOLUTION; i++) {

        if((i - GRID_RESOLUTION/2) % ALIGNMENT_SPACING == 0 || (i - GRID_RESOLUTION/2 - 1) % ALIGNMENT_SPACING == 0) {
            strokeWeight(1);
        } else {
            strokeWeight(0.2);
        }

        int offset = (int)((i) * GRID_SIZE);
        line(offset, 0,   offset, height);
        line(0, offset,   width, offset);
    }

    // Draw circles and lines connecting them
    for (int i = 0; i < points.size(); i++) {
        Point current = points.get(i);
        noStroke();
        circle(
            gridToCanvas(current.x),
            gridToCanvas(current.y),
            POINT_SIZE
        );
        
        stroke(255, 0, 0);
        strokeWeight(GRID_SIZE * 0.3);

        if(i == 0)
            continue;

        Point previous = points.get(i-1);
        if (previous.laser_en) {
            line(
                gridToCanvas(current.x), 
                gridToCanvas(current.y), 
                gridToCanvas(previous.x), 
                gridToCanvas(previous.y)
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
            println("Writing to File");
            writeToFile();
            return;
        }
        println(key);
    }
}


int canvasToGrid(int coord) {
    return floor(coord / GRID_SIZE);
}


float gridToCanvas(int coord) {
    return (coord + 0.5) * GRID_SIZE;
}

void writeToFile() {
    PrintWriter fileX = createWriter("lut_x.txt");
    PrintWriter fileY = createWriter("lut_y.txt");

    for (int i = 0; i < points.size()-2; i++) {
        int x = points.get(i).x;
        int y = points.get(i).y;

        fileX.printf("rom[%d] = 12'd%d;\n", i, x);
        fileY.printf("rom[%d] = 12'd%d;\n", i, y);
    }

    fileX.flush();
    fileY.flush();

    fileX.close();
    fileY.close();
}
