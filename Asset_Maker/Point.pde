class Point {
    
    public int x;
    public int y;
    public boolean laser_en;

    public Point(int x, int y) {
        this.x = x;
        this.y = y;
        this.laser_en = true;
    }

    public void toggle() {
        laser_en = !laser_en;
    }
}
