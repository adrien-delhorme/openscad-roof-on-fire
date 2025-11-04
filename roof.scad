include <constants.scad>
include <openscad-new-dimensions/dimensions.scad>

eps = 0.1;

// We need to "sync" the values of render modes between stairs and dimensions to avoid mixing 2D and 3D objects.
// Dimension has only 2D and 3D render modes: Flat mode is a 3D mode.
DIMENSION_RENDER_MODE = ROOF_RENDER_MODE == ROOF_RENDER_MODE_2D ? DIMENSION_RENDER_MODE_2D : DIMENSION_RENDER_MODE_3D;


module Roof(slopes_vector, render_mode, show_angles) {
  // Use ROOF_<name> if defined, otherwise use default value 
  render_mode = is_undef(render_mode) ? is_undef(ROOF_RENDER_MODE) ? ROOF_RENDER_MODE_3D : ROOF_RENDER_MODE : render_mode;

  // Each slope will draw the next slope in the vector
  // We start by drawing the first slope
  SlopeChain(slopes_vector);

  module SlopeChain(
    slopes_vector,
    index=0,
  ) {
    label = is_undef(slopes_vector[index][2]) ? str("Slope ", index+1) : slopes_vector[index][2];

    dimensions = slopes_vector[index][0];
    slope_angle = index == 0 ? slopes_vector[index][1] : slopes_vector[index][1] - slopes_vector[index-1][1];
    previous_relative_angle = index == 0 ? 0 : slopes_vector[index][1] - slopes_vector[index-1][1];
    next_relative_angle = index == len(slopes_vector)-1 ? 0 : slopes_vector[index+1][1] - slopes_vector[index][1];

    left_cutting_angle = -(180 - previous_relative_angle) / 2;
    right_cutting_angle = -(180 - next_relative_angle) / 2;

    module render3D() {
      rotate([0, slope_angle, 0]) {
        Slope(dimensions, left_cutting_angle, right_cutting_angle, label);

        if (index < len(slopes_vector) - 1) {
          // Move to the end of the current slope to start drawing the next slope
          translate([get_length_bottom(dimensions, left_cutting_angle, right_cutting_angle), 0, 0]) {
            SlopeChain(
              slopes_vector,
              index=index+1,
            );
          }
        }
      }
    }

    module renderFlat() {
      // Mirror even slopes on z axis to align cuts
      z = (index % 2 == 0) ? 1: -1;
      Slope(dimensions, z*left_cutting_angle, z*right_cutting_angle, label, show_angles);

      length_top = get_length_top(dimensions, left_cutting_angle, right_cutting_angle);
      length_bottom = get_length_bottom(dimensions, left_cutting_angle, right_cutting_angle);
      right_junction_length = get_right_junction_length(right_cutting_angle, dimensions.z);
      left_junction_length = get_left_junction_length(left_cutting_angle, dimensions.z);

      if (index < len(slopes_vector) - 1) {
        // Move to the end of the current slope to start drawing the next slope
        translate([
          left_junction_length + right_junction_length + max(length_top, length_bottom) + ROOF_RENDER_GAP_FLAT,
          0,
          0
        ]) {
          SlopeChain(
            slopes_vector,
            index=index+1,
          );
        }
      }
    }

    if (render_mode == ROOF_RENDER_MODE_3D) {
      render3D();
    } else {
      renderFlat();
    }
  }
}

module Slope(dimensions, left_cutting_angle, right_cutting_angle, label, show_angles) {
  render_mode = is_undef(render_mode) ? is_undef(ROOF_RENDER_MODE) ? ROOF_RENDER_MODE_3D : ROOF_RENDER_MODE : render_mode;
  show_angles = is_undef(show_angles) ? is_undef(ROOF_SHOW_ANGLES) ? false : ROOF_SHOW_ANGLES : show_angles;

  show_labels = is_undef(ROOF_SHOW_LABELS) ? false : ROOF_SHOW_LABELS;
  show_dimensions = is_undef(ROOF_SHOW_DIMENSIONS) ? false : ROOF_SHOW_DIMENSIONS;
  dimension_gap = is_undef(ROOF_DIMENSION_GAP) ? 5 : ROOF_DIMENSION_GAP;
  length_bottom = get_length_bottom(dimensions, left_cutting_angle, right_cutting_angle);
  length_top = get_length_top(dimensions, left_cutting_angle, right_cutting_angle);

  module render3D() {
    scale([1, -1, 1]) rotate([90, 0, 0]) {
      linear_extrude(height=dimensions.y) {
        polygon(get_polygon_points(dimensions, left_cutting_angle, right_cutting_angle));
      }
    }
  }

  difference() {
    if (render_mode == ROOF_RENDER_MODE_2D) {
      projection() render3D();
    } else {
      render3D();
    }

    if (show_labels == true) {
      Label(string=label, bbox=[dimensions.x, dimensions.y, dimensions.z], angle=90, height=dimensions.z + eps);
    }
  }

  if (show_dimensions == true) {
    translate([0, -2*dimension_gap, 0])
      Dimension(round(length_bottom));

      z = render_mode == ROOF_RENDER_MODE_2D ? 0 : dimensions.z;
      translate([get_left_junction_length(left_cutting_angle, dimensions.z), -dimension_gap, z])
        Dimension(round(length_top));

    translate([-dimension_gap, 0, 0])
      rotate([0, 0, 90])
        Dimension(round(dimensions.y));
  }

  if (show_angles == true) {
    if (abs(right_cutting_angle) != 90) {
      angle = (right_cutting_angle > 0) ? 180 - right_cutting_angle : -right_cutting_angle;
      translate([max(length_top, length_bottom) - 10, -100, 0])
          AngleOverview(angle, dimensions.z, max_width=20);
    }
  }
}


/*
* left_angle is the angle between the x axis and the left section
* right_angle is the angle between the x axis and the right section
*
*   y                                                                              
*   ^                               length top                                    
*   |                    <-------------------------------->                       
*   +--> x
*                        +--------------------------------+                           
*                       /|                                |\                         ^ 
*                      /                                    \                        | 
*                     /  |                                |  \                       | 
*                    /                                        \                      | 
*                   /    |                                |    \                     | 
*                  /                                            \                    |  height 
*                 /      |                                |      \                   | 
*                /                                                \ _ _ _            | 
*               /\       |                                |        \      \          | 
*  left angle  /  \                                                 \ right\ angle   | 
*             /    \     |                                |          \      \        v 
*            +-----------+--------------------------------+-----------+- - - - - -   
*                                                                                 
*            <---------->                                 <---------->            
*        left junction length                         right junction length       
*                                                                                 
*            <-------------------------------------------------------->           
*                                  length bottom
*/

function get_left_junction_length(angle, height) = abs(angle) % 90 == 0 ? 0 : height / tan(angle);
function get_right_junction_length(angle, height) = abs(180 - angle) % 90 == 0 ? 0 : height / tan(180 - angle);
function get_total_junction_length(left_angle, right_angle, height) = get_left_junction_length(left_angle, height) - get_right_junction_length(right_angle, height);
function get_length_top(dimensions, left_angle, right_angle) = (get_total_junction_length(left_angle, right_angle, dimensions.z) < 0) ? dimensions.x : dimensions.x - abs(get_total_junction_length(left_angle, right_angle, dimensions.z));
function get_length_bottom(dimensions, left_angle, right_angle) = (get_total_junction_length(left_angle, right_angle, dimensions.z) < 0) ? dimensions.x - abs(get_total_junction_length(left_angle, right_angle, dimensions.z)) : dimensions.x;

function get_polygon_points(dimensions, left_angle=90, right_angle=90) = [
  [0, 0],
  [get_length_bottom(dimensions, left_angle, right_angle), 0],
  [get_left_junction_length(left_angle, dimensions.z) + get_length_top(dimensions, left_angle, right_angle), dimensions.z],
  [get_left_junction_length(left_angle, dimensions.z), dimensions.z],
];