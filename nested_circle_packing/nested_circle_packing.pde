/***************************************************************************
 * The circle placement and sizing algorithm in drawFrame is taken from:
 *
 *    Bohnacker, Hartmut, and Gross, Benedikt, and Laub, Julia.
 *    Generative Design: Visualize, Program, and Create with Processing
 *    edited by Lazzeroni, Claudius, Princeton Architectural Press, 2012
 *    pages 232-233
 *
 * and is distributed under the Apache License.
 * 
 * The additional code in this sketch is copyright 2020 Dan Malec
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * -------------------------------------------------------------------------
 *
 * Use a packing algorithm plus mouse clicks to fill the frame with circles.
 * Each circle contains offset nested circles, giving them a bit of a conical
 * appearance. The direction for that offset is selected using Perlin noise.
 * 
 * The Perlin noise has two settings to adjust:
 *   - The initial offset for the entire frame
 *   - The amount to step forward per circle within the frame
 * 
 * This allows you to change the amount of randomness in a frame; but, also
 * explore how different regions of Perlin space (with the same amount of
 * randomness) influence the look.
 *
 * In order to allow different patterns to be explored and captured to SVG,
 * the offset in Perlin space is "snapped back" at the start of rendering each
 * frame.
 ***************************************************************************/


import processing.opengl.*;
import processing.svg.*;
import java.util.Collections;                  


/***************************************************************************
 * Constants
 ***************************************************************************/

// The minimum radius for a circle
static final int MIN_RADIUS = 20;

// The maximum radius for a circle
static final int MAX_RADIUS = 60;

// The size of the gap between nested circles
static final int CIRCLE_NESTING_GAP = 6;

// The rectangle around the mouse click to consider
static final int MOUSE_RECT = 12;

// The maximum number of circles to produce
static final int MAX_CIRCLES = 1000;

// Where each frame should start in Perlin space
static final float PERLIN_START_STEP_AMOUNT = 0.05;

// How far each circle should advance in Perlin space when rendering
static final float PERLIN_VARIATION_STEP_AMOUNT = 0.01;


/***************************************************************************
 * Globals
 ***************************************************************************/

// Boolean flag to trigger capture of the next rendered frame
boolean capture_frame = false;

// Count of captures for building filename
int capture_number = 1;

// List of Circles to render
ArrayList<Circle> circles = new ArrayList();

// The point in Perlin space to use for determining nesting angle
PerlinPoint perlin_point = new PerlinPoint();


/***************************************************************************
 * Classes
 ***************************************************************************/

class Circle {
  float x, y, r;
  
  Circle(float x, float y, float r) {
    this.x = x;
    this.y = y;
    this.r = r;
  }
}

class PerlinPoint {
  float x;
  float dx;

  PerlinPoint() {
    this.x = 0;
    this.dx = 0;
  }

  PerlinPoint(PerlinPoint pp) {
    x = pp.x;
    dx = pp.dx;
  }

  void incX() {
    this.x += dx;
  }
  
  float noiseRange(float min, float max) {
    return min + noise(x) * (max - min);
  }
}


/***************************************************************************
 * Handle sketch settings
 ***************************************************************************/
public void settings() {
  size(500, 500);
}


/***************************************************************************
 * Handle sketch setup
 ***************************************************************************/
void setup() {
  smooth();
  stroke(0);
  strokeWeight(1);
  noFill();
}


/***************************************************************************
 * Handle key presses in order to control the runtime behavior of the sketch.
 *
 * 'c'/'C' : capture the current frame to SVG
 * '<' :     decrease the x position in Perlin space
 * '>' :     increase the x position in Perlin space
 * '-' :     decrease the amount of variation in Perlin space
 * '+' :     increase the amount of variation in Perlin space
 ***************************************************************************/
void keyPressed() {
  switch (key) {
    case 'c':
    case 'C':
      capture_frame = true;
      break;
    
    case '<':
      perlin_point.x -= PERLIN_START_STEP_AMOUNT;
      break;

    case '>':
      perlin_point.x += PERLIN_START_STEP_AMOUNT;
      break;
    
    case '-':
      perlin_point.dx -= PERLIN_VARIATION_STEP_AMOUNT;
      if (perlin_point.dx < 0.0) {
        perlin_point.dx = 0.0;
      }
      break;

    case '+':
      perlin_point.dx += PERLIN_VARIATION_STEP_AMOUNT;
      break;
  }
}


/***************************************************************************
 * Handle frame rendering, including a capture if requested.
 ***************************************************************************/
void draw() {
  background(255);

  if (capture_frame) {
    beginRecord(SVG, "capture_" + capture_number + ".svg");
    capture_number++;
  }

  // By passing in a copy of the PerlinPoint, any changes made during render
  // "snap back" on the next frame.
  drawFrame(new PerlinPoint(perlin_point));

  if (capture_frame) {
    endRecord();
    capture_frame = false;
  }
}


/***************************************************************************
 * Draw one frame.
 ***************************************************************************/
void drawFrame(PerlinPoint perlin_point) {
  float x = random(0 + MAX_RADIUS, width - MAX_RADIUS);
  float y = random(0 + MAX_RADIUS, height - MAX_RADIUS);
  float r = MIN_RADIUS;
  
  if (mousePressed == true) {
    x = random(mouseX - MOUSE_RECT / 2, mouseX + MOUSE_RECT / 2);
    y = random(mouseY - MOUSE_RECT / 2, mouseY + MOUSE_RECT / 2);
    
    x = max(x, 0 + MIN_RADIUS);
    x = min(x, width - MIN_RADIUS);
    
    y = max(y, 0 + MIN_RADIUS);
    y = min(y, height - MIN_RADIUS);
    
    r = 1;
  }

  boolean intersection = false;
  for (Circle c : circles) {
    float d = dist(x, y, c.x, c.y);
    
    if (d < (r + c.r)) {
      intersection = true;
      break;
    }
  }
  
  if (!intersection && (circles.size() < MAX_CIRCLES)) {
    float new_radius = width;
    for (Circle c : circles) {
      float d = dist(x, y, c.x, c.y) - c.r;
      
      if (new_radius > d) {
        new_radius = d;
      }
    }
    
    if (new_radius > MAX_RADIUS) {
      new_radius = MAX_RADIUS;
    }

    new_radius = min(new_radius, width - x);
    new_radius = min(new_radius, x);

    new_radius = min(new_radius, height - y);
    new_radius = min(new_radius, y);
    
    Circle c = new Circle(x, y, new_radius);
    circles.add(c);
  }
  
  for (Circle c : circles) {
    drawCircle(perlin_point, c);
    perlin_point.incX();
  }
}


/***************************************************************************
 * Draw one circle with interior nested circles.
 ***************************************************************************/
void drawCircle(PerlinPoint perlin_point, Circle c) {
  pushMatrix();

  translate(c.x, c.y);
  rotate(perlin_point.noiseRange(0, TWO_PI));
  
  for (float i=(c.r * 2); i>0.0; i-=CIRCLE_NESTING_GAP) {
      circle(i / 2 - c.r, 0, i);
  }
    
  popMatrix();
}
