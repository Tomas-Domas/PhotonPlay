
int GRID_RESOLUTION = 51;
int ALIGNMENT_SPACING = 7;

float GRID_SIZE;

ArrayList<Point> points = new ArrayList<Point>();
PImage img;

void setup() {
  size(760, 760);
  
  fill(255, 0, 0);
  rectMode(CENTER);
  
  GRID_SIZE = min(((float)width / GRID_RESOLUTION), ((float)height / GRID_RESOLUTION));
  
  img = loadImage("UF Logo.png");
  if (img.width > img.height) {
    img.resize(width, 0);
  } else {
    img.resize(0, height);
  }
}


void draw() {
  background(0);
  tint(50);
  image(img, 0, 0);
  
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
    noStroke();
    circle(
      (points.get(i).x + 0.5) * GRID_SIZE, 
      (points.get(i).y + 0.5) * GRID_SIZE, 
      GRID_SIZE * 0.3
    );
    
    stroke(255, 0, 0);
    strokeWeight(GRID_SIZE * 0.2);
    if(i != 0) {
      line(
        (points.get( i ).x + 0.5) * GRID_SIZE, (points.get( i ).y + 0.5) * GRID_SIZE,
        (points.get(i-1).x + 0.5) * GRID_SIZE, (points.get(i-1).y + 0.5) * GRID_SIZE
      );
    }
  }

}


void mousePressed() {
  int col, row;
  for (col = 0; col < GRID_RESOLUTION; col++) {
    if ((col)*GRID_SIZE <= mouseX && mouseX < (col+1)*GRID_SIZE) {
      break;
    }
  }

  for (row = 0; row < GRID_RESOLUTION; row++) {
    if ((row)*GRID_SIZE <= mouseY && mouseY < (row+1)*GRID_SIZE) {
      break;
    }
  }

  if (mouseButton == LEFT) {
    leftClick(col, row);
  } else if (mouseButton == RIGHT) {
    rightClick(col, row);
  }

}


void leftClick(int col, int row) {
  points.add(new Point(col, row));
}


void rightClick(int col, int row) {
  for (int i = points.size()-1; i >= 0; i--) {
    if (points.get(i).x == col && points.get(i).y == row) {
      points.remove(i);
      return;
    }
  }
}


void keyPressed() {
  int x_delta = 0;
  int y_delta = 0;
  if (key == CODED) {
    if (keyCode == UP) {
      y_delta = -1;
    } else if (keyCode == DOWN) {
      y_delta = 1;
    } else if (keyCode == LEFT) {
      x_delta = -1;
    } else if (keyCode == RIGHT) {
      x_delta = 1;
    }

    for (int i = 0; i < points.size(); i++) {
      Point p = points.get(i);
      p.x += x_delta;
      p.y += y_delta;
    }

  }
}