import bpy, math, os
from mathutils import Matrix, Euler
from mathutils import Vector

ROOT = os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.read_factory_settings(use_empty=True)

MATS = {}
def mat(name, color, metallic=0.0, rough=0.75, emission=None):
    if name in MATS: return MATS[name]
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bs = m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value = (*color, 1)
    bs.inputs['Roughness'].default_value = rough
    bs.inputs['Metallic'].default_value = metallic
    if emission:
        bs.inputs['Emission Color'].default_value = (*emission, 1)
        bs.inputs['Emission Strength'].default_value = 2.0
    MATS[name] = m
    return m

SKIN = mat('Skin_warm',(0.94,0.67,0.50),rough=.62)
SKIN2 = mat('Skin_soft',(0.76,0.42,0.30),rough=.68)
HAIR = mat('Hair_ink',(0.07,0.10,0.16),rough=.42)
HAIR2 = mat('Hair_teal',(0.12,0.34,0.37),rough=.44)
EYE = mat('Eyes_lapis',(0.05,0.38,0.62),metallic=.1,rough=.25,emission=None)
GOLD = mat('Trim_gold',(0.94,0.66,0.20),metallic=.55,rough=.30)
IVORY = mat('Cloth_ivory',(0.90,0.83,0.67),rough=.85)
BLUE = mat('Cloth_blue',(0.12,0.30,0.52),rough=.80)
CORAL = mat('Cloth_coral',(0.78,0.24,0.22),rough=.78)
MINT = mat('Cloth_mint',(0.25,0.64,0.55),rough=.78)
WOOD = mat('Wood_warm',(0.34,0.16,0.09),rough=.9)
WOOD2 = mat('Wood_light',(0.62,0.34,0.15),rough=.86)
ROOF = mat('Roof_cerulean',(0.08,0.25,0.42),rough=.72)
ROOF2 = mat('Roof_tile_blue',(0.10,0.37,0.56),rough=.62)
ROOF3 = mat('Roof_tile_cyan',(0.16,0.53,0.65),rough=.58)
LEAF = mat('Leaf_spring',(0.19,0.55,0.24),rough=.9)
LEAF2 = mat('Leaf_light',(0.46,0.78,0.35),rough=.88)
STONE = mat('Stone_lilac',(0.32,0.34,0.43),rough=.92)
CRYSTAL = mat('Crystal_azure',(0.12,0.58,0.78),metallic=.15,rough=.22,emission=(0.04,0.22,0.34))
AIR = mat('Airship_canvas',(0.87,0.71,0.46),rough=.8)
AIRBLUE = mat('Airship_sail',(0.16,0.47,0.55),rough=.65)

def coll(name):
    c=bpy.data.collections.new(name); bpy.context.scene.collection.children.link(c); return c
def set_coll(o,c):
    for cc in list(o.users_collection): cc.objects.unlink(o)
    c.objects.link(o)
def smooth(o):
    if hasattr(o.data,'polygons'):
        for p in o.data.polygons: p.use_smooth=True
def uv(name, loc, scale, material, c, seg=24, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, location=loc)
    o=bpy.context.object; o.name=name; o.scale=scale; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); o.data.materials.append(material); set_coll(o,c); smooth(o); return o
def cube(name, loc, scale, material, c, bevel=.08, rot=None):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot or (0,0,0)); o=bpy.context.object; o.name=name; o.scale=scale; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); o.data.materials.append(material); set_coll(o,c)
    if bevel:
        mod=o.modifiers.new('Soft_edges','BEVEL'); mod.width=bevel; mod.segments=2
    return o
def cyl(name, loc, radius, depth, material, c, vertices=16, rot=None, r2=None):
    # Godot and Blender both use Y-up after glTF conversion; rotate Blender's
    # native Z-axis primitive so all unrotated cylinders stand upright.
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=radius if r2 is None else r2, depth=depth, location=loc, rotation=rot or (math.pi/2,0,0)); o=bpy.context.object; o.name=name; o.rotation_euler=(Euler(rot or (0,0,0)).to_matrix().to_4x4() @ Matrix.Rotation(-math.pi/2,4,'X')).to_euler(); o.data.materials.append(material); set_coll(o,c); smooth(o); return o
def torus(name, loc, major, minor, material, c, rot=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=20, minor_segments=8, location=loc, rotation=rot or (0,0,0)); o=bpy.context.object; o.name=name; o.rotation_euler=(Euler(rot or (0,0,0)).to_matrix().to_4x4() @ Matrix.Rotation(-math.pi/2,4,'X')).to_euler(); o.data.materials.append(material); set_coll(o,c); smooth(o); return o
def cone(name, loc, r1, r2, depth, material, c, vertices=10): return cyl(name,loc,r1,depth,material,c,vertices,r2=r2)

def build_hero(c, companion=False):
    skin=SKIN2 if companion else SKIN; hair=HAIR2 if companion else HAIR; cloth=MINT if companion else BLUE; accent=CORAL if companion else GOLD
    tag='Companion' if companion else 'Player';
    cyl(tag+'_Torso',(0,1.35,0),.43,1.05,cloth,c,vertices=12,r2=.34)
    cube(tag+'_ChestPanel',(0,1.45,-.36),(.28,.30,.055),IVORY,c,.04)
    cube(tag+'_Waist',(0,.82,0),(.44,.12,.34),accent,c,.04)
    for x in (-.19,.19):
        cyl(tag+'_Leg',(x,.40,0),.14,.72,IVORY,c,vertices=10)
        cube(tag+'_Boot',(x,.08,-.09),(.20,.11,.34),HAIR,c,.05)
    for x in (-.53,.53):
        cyl(tag+'_Sleeve',(x,1.40,0),.14,.73,cloth,c,vertices=10,rot=(0,0,math.radians(-12 if x<0 else 12)))
        uv(tag+'_Glove',(x*1.06,1.03,-.01),(.16,.15,.16),skin,c,16,8)
    uv(tag+'_Head',(0,2.18,0),(.46,.48,.43),skin,c,20,12)
    # anime eyes and brow accents
    for x in (-.17,.17):
        uv(tag+'_Eye',(x,2.24,-.435),(.085,.115,.035),EYE,c,16,8)
        cube(tag+'_Brow',(x,2.38,-.42),(.10,.025,.025),hair,c,.02,rot=(0,math.radians(8 if x<0 else -8),math.radians(4 if x<0 else -4)))
    # layered bangs plus side locks
    uv(tag+'_HairCap',(0,2.58,.04),(.49,.24,.44),hair,c,20,10)
    for i,(x,z,s) in enumerate([(-.38,-.18,.24),(-.20,-.34,.22),(0,-.40,.21),(.20,-.34,.22),(.38,-.18,.24)]):
        cone(tag+'_Bang_%02d'%i,(x,2.49,z),.025,s*.68,.25,hair,c,8)
    for x in (-.48,.48):
        cone(tag+'_SideLock_'+str(x),(x,2.10,.02),.12,.035,.72,hair,c,8)
    torus(tag+'_Scarf',(0,1.76,0),.47,.075,accent,c,rot=(math.radians(90),0,0))
    cape=cube(tag+'_Cape',(0,1.35,.34),(.44,.72,.055),accent,c,.05,rot=(math.radians(8),0,0))
    uv(tag+'_Pendant',(0,1.62,-.43),(.10,.10,.05),CRYSTAL,c,16,8)
    if companion:
        torus(tag+'_HairRibbon',(0,2.66,0),.29,.055,CORAL,c,rot=(math.radians(90),0,0))
    return c

def build_tree(c):
    cyl('Tree_Trunk',(0,2.0,0),.55,4.0,WOOD,c,vertices=10,r2=.38)
    for i in range(5):
        a=i*math.tau/5; cyl('Tree_Branch_%02d'%i,(math.cos(a)*.62,3.35,math.sin(a)*.62),.20,2.1,WOOD2,c,vertices=8,rot=(0,math.sin(a)*.35,-math.cos(a)*.35))
    for i,(x,y,z,s) in enumerate([(0,4.6,0,1.9),(-1.05,4.4,.2,1.35),(1.12,4.5,-.1,1.35),(.15,5.5,.25,1.25),(-.1,3.95,-.8,1.2)]):
        uv('Tree_Canopy_%02d'%i,(x,y,z),(s,s*.82,s),LEAF if i%2 else LEAF2,c,20,12)
    for i in range(4): uv('Tree_Fruit_%02d'%i,((i-1.5)*.55,4.8+(.2 if i%2 else 0),-.9),(.11,.11,.11),GOLD,c,12,6)

def build_house(c):
    cube('House_Wall',(0,2.2,0),(3.8,2.2,3.0),IVORY,c,.12)
    # exposed timber frame
    for x in (-3.0,3.0): cube('House_VerticalBeam',(x,2.3,-3.08),(.16,2.0,.13),WOOD2,c,.04)
    for y in (1.0,3.6): cube('House_HorizontalBeam',(0,y,-3.1),(3.25,.15,.13),WOOD2,c,.04)
    # Rectangular gable roof, with its ridge running along the house depth.
    eave_x, eave_y, roof_z, ridge_y = 4.5, 4.62, 3.72, 6.25
    pitch = math.atan2(ridge_y-eave_y, eave_x)
    slope_len = math.hypot(eave_x, ridge_y-eave_y)
    # Close the attic below the slopes so the gable reads as a solid house.
    section = [(-3.8,4.4),(3.8,4.4),(3.8,4.73),(0,6.10),(-3.8,4.73)]
    verts = [(x,y,z) for z in (-3.0,3.0) for x,y in section]
    faces = [tuple(reversed(range(5))), tuple(range(5,10))]
    faces += [(i,(i+1)%5,(i+1)%5+5,i+5) for i in range(5)]
    mesh = bpy.data.meshes.new('House_Gable_Fill'); mesh.from_pydata(verts,[],faces); mesh.update()
    gable = bpy.data.objects.new('House_Gable_Fill',mesh); c.objects.link(gable); mesh.materials.append(IVORY)
    for side in (-1, 1):
        angle = -side*pitch
        cube('House_Roof_Slope', (side*eave_x/2, (eave_y+ridge_y)/2, 0),
             (slope_len/2, .14, roof_z), ROOF, c, .035, rot=(0,0,angle))
        for row in range(5):
            run = (row+.5)*.9
            x = side*run*math.cos(pitch)
            y = ridge_y-run*math.sin(pitch)+.12
            for col in range(10):
                z = -3.92+col*.87+(.435 if row%2 else 0)
                z0, z1 = max(-roof_z,z-.46), min(roof_z,z+.46)
                if z1-z0 < .07: continue
                cube('House_Roof_Tile_%d_%d' % (side,row*10+col), (x,y,(z0+z1)/2),
                     (.53,.065,(z1-z0)/2), ROOF2 if (row+col)%2 else ROOF3, c, .035,
                     rot=(0,0,angle))
        cube('House_Eave_Fascia', (side*eave_x, eave_y, 0),
             (.14,.14,roof_z+.12), WOOD2, c, .035)
        for z in (-roof_z, roof_z):
            cube('House_Gable_Fascia', (side*eave_x/2, (eave_y+ridge_y)/2, z),
                 (slope_len/2,.11,.12), WOOD2, c, .03, rot=(0,0,angle))
    cube('House_Ridge_Cap', (0,ridge_y+.035,0), (.18,.14,roof_z+.12), ROOF2,c,.06)
    cube('House_Door',(0,1.55,-3.18),(.72,1.35,.10),WOOD,c,.06)
    torus('House_DoorRing',(0,1.55,-3.31),.16,.035,GOLD,c,rot=(math.radians(90),0,0))
    for x in (-2.0,2.0):
        cube('House_WindowFrame',(x,2.8,-3.2),(.62,.62,.08),WOOD2,c,.05)
        cube('House_WindowGlow',(x,2.8,-3.30),(.44,.44,.04),GOLD,c,.03)
        cube('House_MullionV',(x,2.8,-3.38),(.045,.48,.03),WOOD,c,.01)
        cube('House_MullionH',(x,2.8,-3.38),(.48,.045,.03),WOOD,c,.01)
    return c

def build_rock(c):
    for i,(x,y,z,s) in enumerate([(0,0,0,1.7),(.9,.1,.2,1.0),(-.8,.15,.2,.8)]):
        cone('Rock_Facet_%02d'%i,(x,y+1.0,z),s*.85,s*.48,2.0*s,STONE if i else CRYSTAL,c,7)
    for i in range(3): cone('Crystal_Shard_%02d'%i,((i-1)*.4,1.9,(i%2)*.3-.2),.20,.02,2.2,CRYSTAL,c,6)

def build_airship(c):
    uv('Airship_Balloon',(0,6.5,0),(5.4,2.2,8.5),AIR,c,32,16)
    for x in (-3.2,3.2): cyl('Airship_Rope',(x,3.2,0),.07,5.2,WOOD,c,8)
    cube('Airship_Deck',(0,1.0,0),(2.5,.25,5.2),WOOD,c,.10)
    cube('Airship_Bridge',(0,1.7,-1.2),(1.35,.55,1.35),AIRBLUE,c,.10)
    for z in (-4.5,4.5):
        cone('Airship_Fin',(0,4.5,z),1.15,.10,2.8,AIRBLUE,c,4)
    for x in (-2.0,2.0):
        for z in (-3.8,3.8): cyl('Airship_Mast',(x,3.2,z),.09,4.4,GOLD,c,8)
    torus('Airship_Emblem',(0,2.45,-2.65),.55,.08,GOLD,c,rot=(math.radians(90),0,0))

def build_lighthouse(c):
    cyl('Lighthouse_Tower',(0,5.0,0),2.1,10.0,IVORY,c,vertices=16,r2=1.45)
    for y in (2.0,5.2,8.4): torus('Lighthouse_Ring',(0,y,0),1.72,.12,WOOD2,c)
    cube('Lighthouse_Door',(0,1.6,-1.55),(.55,1.3,.08),WOOD,c,.05)
    for x in (-.88,.88):
        cube('Lighthouse_Window',(x,5.8,-1.37),(.40,.72,.06),CRYSTAL,c,.04)
    cylinder = cyl('Lighthouse_Gallery',(0,10.3,0),2.35,.45,WOOD2,c,vertices=16)
    cyl('Lighthouse_Lantern',(0,11.25,0),1.55,1.5,CRYSTAL,c,vertices=16)
    cone('Lighthouse_Roof',(0,12.45,0),1.9,.18,2.0,ROOF,c,vertices=8)
    cyl('Lighthouse_Star',(0,13.5,0),.15,.9,GOLD,c,vertices=8)

collections=[]
builders=[('Hero_Player',lambda c:build_hero(c,False)),('Hero_Companion',lambda c:build_hero(c,True)),('Tree_Fantasy',build_tree),('House_Fantasy',build_house),('Rock_Crystal',build_rock),('Airship_Landmark',build_airship),('Lighthouse_Beacon',build_lighthouse)]
for name,fn in builders:
    c=coll(name); fn(c); collections.append((name,c))

# Authoring above uses an intuitive Y-up coordinate convention. Blender is Z-up,
# so rotate each asset collection into native Blender orientation. Godot's glTF
# importer performs the inverse axis conversion and restores intended Y-up poses.
from mathutils import Matrix
axis_fix=Matrix.Rotation(math.radians(90),4,'X')
for _name,c in collections:
    for o in c.objects:
        o.matrix_world=axis_fix @ o.matrix_world

# A display collection makes the combined GLB easy to inspect; game imports per-asset GLBs.
display=coll('Asset_Display')
for idx,(name,c) in enumerate(collections):
    for o in list(c.objects):
        dup=o.copy(); dup.data=o.data.copy() if hasattr(o.data,'copy') else o.data; display.objects.link(dup); dup.location.x += (idx%3)*15-15; dup.location.z += (idx//3)*14-7

bpy.context.scene['asset_source']='Original procedural bpy mesh by build_fantasy_assets.py; no external downloads.'
bpy.context.scene['asset_style']='Bright anime fantasy adventure; layered silhouettes and hand-authored materials.'
bpy.context.scene['asset_collections']='Hero_Player, Hero_Companion, Tree_Fantasy, House_Fantasy, Rock_Crystal, Airship_Landmark'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'fantasy_assets.blend'))

def export(path, objects):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects: o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0] if objects else None
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_apply=True, export_materials='EXPORT')

export(os.path.join(ROOT,'fantasy_assets.glb'), [o for _name,c in collections for o in c.objects])
for name,c in collections:
    export(os.path.join(ROOT,name.lower()+'.glb'), list(c.objects))
print('BLENDER_ASSETS_CREATED', os.path.join(ROOT,'fantasy_assets.blend'))


