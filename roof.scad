include <BOSL/constants.scad>
use <BOSL/shapes.scad>
use <BOSL/transforms.scad>
include <dimensions/dimensions.scad>

eps = 0.1;

module SlopeShape(dimensions, left_angle=90, right_angle=90, render_mode) {
  /* left_angle is the angle between the x axis and the left section
   * right_angle is the angle between the x axis and the right section
   *                                                                                  
   *                                   length top                                    
   *                        <-------------------------------->                       
   *               shift                                                             
   *            <- - - - -> +--------------------------------+                           
   *                       /|                                |\                         ^ 
   *                      /                                    \                        | 
   *                     /  |                                |  \                       | 
   *                    /                                        \                      | 
   *                   /    |                                |    \                     | 
   *                  /                                            \                    |  height 
   *                 /      |                                |      \                   | 
   *                /                                                \                  | 
   *               /\       |                                |       /\                 | 
   *  left angle  /  \                                              /  \  right angle   | 
   *             /    \     |                                |     /    \               v 
   *            +-----------+--------------------------------+-----------+            
   *                                                                                 
   *            <---------->                                 <----------->           
   *        left junction length                         right junction length       
   *                                                                                 
   *            <-------------------------------------------------------->           
   *                              length bottom = length
   *
   */
   
  render_mode = (render_mode == undef) ? ROOF_RENDER_MODE : render_mode;
  length = dimensions[0];
  depth = dimensions[1];
  height = dimensions[2];
  left_junction_length = tan(min($fa, 90+left_angle)) * height; // $fa is the minimum angle
  right_junction_length = tan(max($fa, 90+right_angle)) * height;
  shift = (left_junction_length + right_junction_length) / 2;

  length_top = -left_junction_length + length + right_junction_length;
  length_bottom = length;

  if (render_mode == "3D") {
    prismoid(
      size1=[length_bottom, depth],
      size2=[length_top, depth],
      h=height,
      shift=[shift, 0],
      orient=ORIENT_Z,
      align=V_BACK+V_RIGHT+V_UP
    );
  } else {
    translate([max(0, -left_junction_length), 0, 0]) {
      prismoid(
        size1=[length_bottom, depth],
        size2=[length_top, depth],
        h=height,
        shift=[shift, 0],
        orient=ORIENT_Z,
        align=V_BACK+V_RIGHT+V_UP
      );
    }
  }

  if (ROOF_SHOW_DIMENSIONS == true) {
    translate([0, -DIMENSION_GAP, 0])
      Dimension(round(length_top));
    translate([-DIMENSION_GAP, 0, 0])
      rotate([0, 0, 90])
        Dimension(round(depth));
    }
}

module Roof(slopes_vector, render_mode) {
  render_mode = (render_mode == undef) ? ROOF_RENDER_MODE : render_mode;

  module Slope(
    dimensions,
    angle,
    left_relative_angle=0,
    right_relative_angle=0,
    index,
    label=undef
  ) {
    // angle is the angle between the x axis and the Slope
    // left_relative_angle is the angle between the previous Slope and this one
    // right_relative_angle is the angle between this Slope and the next
    // index is the position of the slope in the generated list, starting with 0

    let (label = (label == undef) ? str(parent_module(0), " ", index+1) : label) {
      if (render_mode == "3D") {
        rotate([0, angle, 0]) {
          difference() {
            SlopeShape(dimensions, -90 + left_relative_angle/2, 90 - right_relative_angle/2, render_mode);
            if (ROOF_SHOW_LABELS == true) {
              Label(dimensions.x, dimensions.y, dimensions.z, string=label);
            }
          }
        }
      } else {
        difference() {
          SlopeShape(dimensions, -90 + left_relative_angle/2, 90 - right_relative_angle/2, render_mode);
          if (ROOF_SHOW_LABELS == true) {
            Label(dimensions.x, dimensions.y, dimensions.z, string=label);
          }
        }
      }
    }
  }

  function x_projection(vector, padding=0) = 
    len(vector) == 1 ?
      vector[0][0][0] * cos(vector[0][1]) :
      vector[len(vector)-1][0][0] * cos(vector[len(vector)-1][1]) + padding + x_projection([for (a = [0:len(vector)-2]) vector[a]], padding);

  function y_projection(vector, padding=0) = 
    len(vector) == 1 ?
      vector[0][0][1] * cos(vector[0][1]) :
      vector[len(vector)-1][0][1] * cos(vector[len(vector)-1][1]) + padding + y_projection([for (a = [0:len(vector)-2]) vector[a]], padding);

  function z_projection(vector) = 
    len(vector) == 1 ?
      vector[0][0][0] * -sin(vector[0][1]) :
      vector[len(vector)-1][0][0] * -sin(vector[len(vector)-1][1]) + z_projection([for (a = [0:len(vector)-2]) vector[a]]);
  
  for (
    x_index = [0:len(slopes_vector)-1]
  ) {
    let (slope_vector = slopes_vector[x_index], dimensions = slope_vector[0], angle = slope_vector[1], label = slope_vector[2]) {
      if (render_mode == "3D") {
        if (x_index == 0) { // first slope
          right_relative_angle = slopes_vector[x_index][1] - slopes_vector[x_index+1][1];
          Slope(
            dimensions,
            angle,
            right_relative_angle=right_relative_angle,
            index=x_index,
            label=label
          );
        } else if (x_index == len(slopes_vector)-1) { // last slope
          previous_slopes_vector = [for (i = [0:x_index-1]) [slopes_vector[i][0], slopes_vector[i][1]]];
          left_relative_angle = slopes_vector[x_index-1][1] - slopes_vector[x_index][1];

          translate([x_projection(previous_slopes_vector), 0, z_projection(previous_slopes_vector)])
            Slope(
              dimensions,
              angle,
              left_relative_angle=left_relative_angle,
              index=x_index,
              label=label
            );
        } else {  // in between slopes
          previous_slopes_vector = [for (i = [0:x_index-1]) [slopes_vector[i][0], slopes_vector[i][1]]];
          left_relative_angle = slopes_vector[x_index-1][1] - slopes_vector[x_index][1];
          right_relative_angle = slopes_vector[x_index][1] - slopes_vector[x_index+1][1];

          // Add eps here to avoid glitches when used with difference()
          translate([x_projection(previous_slopes_vector) -eps, 0, z_projection(previous_slopes_vector)])
            Slope(
              dimensions,
              angle,
              left_relative_angle=left_relative_angle,
              right_relative_angle=right_relative_angle,
              index=x_index,
              label=label
            );
        }
      } else {
        if (x_index == 0) { // first slope
          right_relative_angle = slopes_vector[x_index][1] - slopes_vector[x_index+1][1];
          Slope(
            dimensions,
            0,
            right_relative_angle=right_relative_angle,
            index=x_index,
            label=label
          );
          if (ROOF_SHOW_DIMENSIONS == true)  {
            translate([dimensions[0] + 50, 0])
              AngleOverview(90 + right_relative_angle/2, dimensions[2], label=str("Angle ", label));
          }
        } else if (x_index == len(slopes_vector)-1) { // last slope
          previous_slopes_vector = [for (i = [0:x_index-1]) [slopes_vector[i][0], 0]];
          left_relative_angle = slopes_vector[x_index-1][1] - slopes_vector[x_index][1];

          translate([0, y_projection(previous_slopes_vector, ROOF_GAP_2D) + ROOF_GAP_2D])
            Slope(
              dimensions,
              0,
              left_relative_angle=left_relative_angle,
              index=x_index,
              label=label
            );
        } else { // in between slope
          previous_slopes_vector = [for (i = [0:x_index-1]) [slopes_vector[i][0], 0]];
          left_relative_angle = slopes_vector[x_index-1][1] - slopes_vector[x_index][1];
          right_relative_angle = slopes_vector[x_index][1] - slopes_vector[x_index+1][1];

          translate([0, y_projection(previous_slopes_vector, ROOF_GAP_2D) + ROOF_GAP_2D]) {
            Slope(
              dimensions,
              angle,
              left_relative_angle=left_relative_angle,
              right_relative_angle=right_relative_angle,
              index=x_index,
              label=label
            );
            if (ROOF_SHOW_DIMENSIONS == true)  {
              translate([dimensions[0] + 50, 0])
                AngleOverview(90 + right_relative_angle/2, dimensions[2], label=str("Angle ", label));
            }
          }
        }
      }
    }
  }
}

/* Roof([ // a vector of slope vectors [dimensions, angle with x axis]
 *   [[30, 50, 5], -140, "label 1"],
 *   [[100, 50, 5], -45],
 *   [[100, 50, 5], 70],
 *   [[30, 50, 5], 90]
/* ]); */
