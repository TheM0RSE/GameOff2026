PSX Skyboxes: Space & Nebula - 5 PS1-style skyboxes (v1.0)

Skyboxes in this pack
- purple_nebula      magenta and violet nebula clouds in deep space
- blue_nebula        teal and blue gas clouds, bright star field
- ringed_planet      a banded gas giant with rings and a small moon
- deep_starfield     black space packed with stars, a faint star band
- galaxy_core        the glowing core of a galaxy with dark dust lanes

Also in the pack
- Preview/panoramas.png  all panoramas with their names
- Preview/scenes.png  a small low-poly scene rendered in Blender under each skybox
- LICENSE.txt

Files per skybox (one folder per skybox)
- panorama_1024x512.png   equirectangular panorama (2:1), the easiest way into any engine
- cube_256/  px.png nx.png py.png ny.png pz.png nz.png   cubemap faces, 256x256
             strip_6x1.png   the same six faces side by side in the order +X -X +Y -Y +Z -Z
- cube_512/  the same at 512x512 per face

Directions: +Y is up, +Z is forward, +X is right (Unity axes). The centre of the panorama
looks along +Z. Face names: px = +X (right), nx = -X (left), py = +Y (up), ny = -Y (down),
pz = +Z (front), nz = -Z (back). The faces follow the usual cubemap layout (as used by OpenGL,
Direct3D, Unity and Godot), and every edge was checked against the neighbouring face.

The colours are 15-bit (5 bits per channel, like the PS1) with ordered 4x4 dithering.
Keep texture filtering on Nearest / Point and turn mipmaps and compression off, otherwise the
dither pattern turns into mush.

Godot 4
Panorama (simplest):
 1. Import panorama_1024x512.png. In the Import dock turn Mipmaps off and reimport.
 2. WorldEnvironment > Environment > Background: Sky. Sky > Sky Material: New PanoramaSkyMaterial.
 3. Put the panorama into Panorama. If your Godot version shows a Filter option on the
    material, turn it off for crisp pixels.
Cubemap (sharper, 512 per face):
 1. Select cube_512/strip_6x1.png, Import As: Cubemap, Slices > Arrangement: 6x1 (Godot reads
    the slices in the order +X -X +Y -Y +Z -Z, the order of the strip). Mipmaps off, Reimport.
 2. Sky Material: New ShaderMaterial with this sky shader:
      shader_type sky;
      uniform samplerCube sky_cube : source_color, filter_nearest;
      void sky() { COLOR = texture(sky_cube, EYEDIR * vec3(1.0, 1.0, -1.0)).rgb; }
    (the z flip makes the pack's forward (+Z) face Godot's forward (-Z)), then assign the cubemap.

Unity
Panorama:
 1. Import panorama_1024x512.png. Texture Shape: Cube, Mapping: Latitude-Longitude Layout,
    Filter Mode: Point, Generate Mip Maps off, Compression: None. Apply.
 2. Create a material with the shader Skybox/Cubemap and put the texture in the Cubemap slot.
 3. Window > Rendering > Lighting > Environment > Skybox Material: your material.
Six faces (6 Sided skybox):
 1. Import the six PNGs from cube_512/ with Wrap Mode: Clamp, Filter Mode: Point,
    Generate Mip Maps off, Compression: None.
 2. Material with shader Skybox/6 Sided:
      Front [+Z] = pz.png   Back [-Z] = nz.png   Left [+X] = px.png
      Right [-X] = nx.png   Up [+Y] = py.png     Down [-Y] = ny.png
    (Unity's own labels: the slot named "Left [+X]" takes the +X face.)

Tips for the PS1 look
- Fog: set the fog colour to the colour of the sky just above the horizon in the direction
  your camera mostly faces, and let distant geometry fade into it.
- Light: each skybox has a clear light source (sun, moon, glow, lightning). Point your
  directional light from there and tint it with the same colour.
- Rotate the sky instead of the level if the sun is on the wrong side (Godot: Sky Rotation,
  Unity: Rotation on the skybox material).

More in the series
- All 8 PSX Skyboxes packs, plus every future pack: https://juliusschmidt.itch.io/psx-skyboxes-complete
- Matching tileable textures: PSX Textures Complete (https://juliusschmidt.itch.io/psx-textures-complete)
- Matching low-poly props: PSX Props Complete (https://juliusschmidt.itch.io/psx-props-complete)

More packs like this
--------------------

Part of the PSX Skyboxes series.
All 8 packs, plus every pack added later, are in PSX Skyboxes Complete (https://juliusschmidt.itch.io/psx-skyboxes-complete) for 4.99 USD.
Made to go with the tileable textures of PSX Textures Complete (https://juliusschmidt.itch.io/psx-textures-complete) and the low-poly models of PSX Props Complete (https://juliusschmidt.itch.io/psx-props-complete): same colour rules, same dither.
