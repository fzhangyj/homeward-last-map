import bpy, json, math, os
from mathutils import Matrix, Vector

# Inspect the saved meshes in the generator's Y-up authoring coordinates.
author = Matrix.Rotation(-math.pi/2, 4, 'X')
house = bpy.data.collections['House_Fantasy']
slopes = [o for o in house.objects if o.name.startswith('House_Roof_Slope')]
tiles = [o for o in house.objects if o.name.startswith('House_Roof_Tile_')]
assert len(slopes) == 2 and len(tiles) >= 80
boxes = []
for obj in slopes:
    points = [author @ obj.matrix_world @ Vector(p) for p in obj.bound_box]
    boxes.append({'min': [min(p[i] for p in points) for i in range(3)],
                  'max': [max(p[i] for p in points) for i in range(3)]})
assert min(b['min'][0] for b in boxes) <= -4.3
assert max(b['max'][0] for b in boxes) >= 4.3
assert all(b['min'][2] <= -3.5 and b['max'][2] >= 3.5 for b in boxes)
assert all(b['min'][1] > 4.4 for b in boxes)
# At each actual wall corner, cast vertically down onto a roof slab.
hits = []
for x in (-3.8, 3.8):
    for z in (-3.0, 3.0):
        native = author.inverted() @ Vector((x, 10, z))
        direction = author.inverted().to_3x3() @ Vector((0, -1, 0))
        for obj in slopes:
            inverse = obj.matrix_world.inverted()
            hit, position, normal, index = obj.ray_cast(inverse @ native, inverse.to_3x3() @ direction)
            if hit:
                y = (author @ obj.matrix_world @ position).y
                assert y > 4.4
                hits.append([x, z, round(y, 4)])
                break
        else:
            raise AssertionError('Uncovered wall corner: %s' % ((x, z),))
print('ROOF_GEOMETRY_PASS', json.dumps({'slopes': len(slopes), 'tiles': len(tiles), 'slope_bounds': boxes, 'covered_corners': hits}))
