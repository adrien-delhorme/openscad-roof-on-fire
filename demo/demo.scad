include <openscad-roof-on-fire/roof.scad>;

/* [View] */
// Choose the rendering mode
ROOF_RENDER_MODE = "3D"; // [3D, Flat, 2D]

// Space between 2D elements
ROOF_RENDER_GAP_FLAT = 20;

/* [Dimensions] */
// Check to show dimensions
ROOF_SHOW_DIMENSIONS = true;

// Check to show angles overview
ROOF_SHOW_ANGLES = true;

// Space between dimensions and elements
ROOF_DIMENSION_GAP = 5;

// Color
DIMENSION_COLOR = "black"; // [aliceblue antiquewhite, aqua, aquamarine, azure, beige, bisque, black, blanchedalmond, blue, blueviolet, brown, burlywood, cadetblue, chartreuse, chocolate, coral, cornflowerblue, cornsilk, crimson, cyan, darkblue, darkcyan, darkgoldenrod, darkgray, darkgreen, darkgrey, darkkhaki, darkmagenta, darkolivegreen, darkorange, darkorchid, darkred, darksalmon, darkseagreen, darkslateblue, darkslategray, darkslategrey, darkturquoise, darkviolet, deeppink, deepskyblue, dimgray, dimgrey, dodgerblue, firebrick, floralwhite, forestgreen, fuchsia, gainsboro, ghostwhite, gold, goldenrod, gray, green, greenyellow, grey, honeydew, hotpink, indianred, indigo, ivory, khaki, lavender, lavenderblush, lawngreen, lemonchiffon, lightblue, lightcoral, lightcyan, lightgoldenrodyellow, lightgray, lightgreen, lightgrey, lightpink, lightsalmon, lightseagreen, lightskyblue, lightslategray, lightslategrey, lightsteelblue, lightyellow, lime, limegreen, linen, magenta, maroon, mediumaquamarine, mediumblue, mediumorchid, mediumpurple, mediumseagreen, mediumslateblue, mediumspringgreen, mediumturquoise, mediumvioletred, midnightblue, mintcream, mistyrose, moccasin, navajowhite, navy, oldlace, olive, olivedrab, orange, orangered, orchid, palegoldenrod, palegreen, paleturquoise, palevioletred, papayawhip, peachpuff, peru, pink, plum, powderblue, purple, red, rosybrown, royalblue, saddlebrown, salmon, sandybrown, seagreen, seashell, sienna, silver, skyblue, slateblue, slategray, slategrey, snow, springgreen, steelblue, tan, teal, thistle, tomato, turquoise, violet, wheat, white, whitesmoke, yellow, yellowgreen]

// Line width
DIMENSION_LINE_WIDTH = 0.5;

// Font size
DIMENSION_FONTSIZE = 0.5;

/* [Labels] */
// Check to show labels
ROOF_SHOW_LABELS = false;


/* [Roof] */
material_thickness = 10;
width = 500;


Roof([ // a vector of slope vectors [dimensions, angle with x axis]
  [[100, width, material_thickness], -33],
  [[200, width, material_thickness], -66],
  [[200, width, material_thickness], 66],
  [[100, width, material_thickness], 33]
]);

translate([500, 0, 0]) {
  Roof([
    [[100, width, material_thickness], -33],
    [[200, width, material_thickness], -66],
    [[200, width, material_thickness], 66],
    [[100, width, material_thickness], 33]
  ], ROOF_RENDER_MODE_2D, show_angles=true);
}