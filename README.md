# Lithium
LithiumGl is a 3D rendering engine made on batch. Its not intendended to be used profesionally as this was just a hobby side-project i made

## How does it works
It reads a model, makes the points and then connect the points using the Bresenham's algorithm to connect them in any octant. For the third dimension a weak perspective is rendered.

Also, it makes a register to change the font to a bitmap 8x8, so the pixels are squares and not rectangles.

## Creating a model
To create a model make a file and name it "mymodel.lith". Then u can define the vertex writing in a new line their coords.
Example :
```
10 0 1
X  Y Z
```

## Joining vertex
As easy as writing #number, number being the vertex index u want to connect.
Example :
```
10 0 1 1
30 0 1
```

## Model settings
U can set the X/Y Offset of a model by writing ? and then x|number and y|number
Example : 
```
? x|5 y|5
```
