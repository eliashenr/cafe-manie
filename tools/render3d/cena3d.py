"""Cena comum da arte 3D (DT-084): luz, câmera no ângulo do jogo, recorte das fotos e gravação em art/sprites.

Usada por personagens3d.py e moveis3d.py, dentro do Blender.

Medidas do jogo: 1 unidade = o lado de um piso; câmera ortográfica girada (60°, 0, 45°), que dá o piso 2:1; com a
densidade 2 das texturas, 1 unidade na horizontal da tela = 181 pixels de imagem. O piso (x, y) do jogo ocupa X de x a
x+1 e Y de -y-1 a -y (o y do jogo vira -Y). Alturas da arte 2D: 1 pixel do desenho (no piso de 96) = DESIGN_Z unidade.
"""
import json
import math
import os

import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SPRITES = os.path.join(ROOT, "art", "sprites")
DENSITY = 2.0
PX_PER_UNIT = 128.0 / math.sqrt(2.0) * DENSITY
DESIGN_Z = (1.0 / 96.0) * math.sqrt(2.0) / math.cos(math.radians(30.0))
CAMERA_ROTATION = (math.radians(60.0), 0.0, math.radians(45.0))
MIN_ALPHA = 22.0 / 255.0   # abaixo disto é o véu do chão que recebe a sombra, não o desenho
CROP_PAD = 4


def linear(hex_color, alpha=1.0):
    """#rrggbb (sRGB) -> cor linear do Blender (RGBA)."""
    h = hex_color.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return (*out, alpha)


def setup(samples, size, shadow_center=(0.0, 0.0), shadow_size=3.0, tiling=False, sun=3.4):
    """Cena vazia com a luz do jogo: sol quente de cima (a sombra cai curta, para trás), preenchimento frio e
    contorno; o chão invisível recebe a sombra. [shadow_size] é o lado do chão, ou (largura, fundo) para a sombra
    não passar da pegada do móvel. [tiling]: pisos e paredes, que se repetem lado a lado: só luz direcional (a luz
    de área ilumina cada trecho de um jeito e o desenho mostraria a emenda). [sun]: força do sol (o chão, que recebe o sol
    de frente, usa menos, senão as cores claras estouram)."""
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    scene.render.resolution_percentage = 100
    scene.render.resolution_x, scene.render.resolution_y = size
    scene.camera = None
    world = scene.world or bpy.data.worlds.new("Mundo")
    scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.62, 0.68, 0.78, 1.0)
    background.inputs["Strength"].default_value = 0.6
    _light("Sol", "SUN", sun, (1.0, 0.92, 0.8), direction=Vector((-0.12, 0.35, -0.93)), angle=18.0)
    if tiling:
        _light("Preenchimento", "SUN", 0.9, (0.78, 0.86, 1.0), direction=Vector((-4.0, 4.0, -3.0)), angle=40.0)
        _light("Contorno", "SUN", 0.4, (1.0, 1.0, 1.0), direction=Vector((2.5, -2.5, -3.0)), angle=40.0)
    else:
        _light("Preenchimento", "AREA", 140.0, (0.78, 0.86, 1.0), location=(4.0, -4.0, 3.0), euler=(60.0, 0.0, 45.0), size=4.0)
        _light("Contorno", "AREA", 80.0, (1.0, 1.0, 1.0), location=(-2.5, 2.5, 3.0), euler=(-55.0, 0.0, -135.0), size=2.0)
    width, depth = shadow_size if isinstance(shadow_size, tuple) else (shadow_size, shadow_size)
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(shadow_center[0], shadow_center[1], 0.0))
    catcher = bpy.context.active_object
    catcher.scale = (width, depth, 1.0)
    catcher.is_shadow_catcher = True


def _light(name, kind, energy, color, direction=None, location=(0, 0, 0), euler=(0, 0, 0), size=1.0, angle=0.0):
    data = bpy.data.lights.new(name, kind)
    data.energy = energy
    data.color = color
    if kind == "SUN":
        data.angle = math.radians(angle)
    else:
        data.size = size
    obj = bpy.data.objects.new(name, data)
    obj.location = location
    if direction is not None:
        obj.rotation_mode = "QUATERNION"
        obj.rotation_quaternion = direction.normalized().to_track_quat("-Z", "Y")
    else:
        obj.rotation_euler = tuple(math.radians(a) for a in euler)
    bpy.context.scene.collection.objects.link(obj)


def aim_camera(target):
    scene = bpy.context.scene
    cam = scene.camera
    if cam is None:
        data = bpy.data.cameras.new("Camera")
        data.type = "ORTHO"
        data.clip_end = 40.0
        cam = bpy.data.objects.new("Camera", data)
        scene.collection.objects.link(cam)
        cam.rotation_euler = CAMERA_ROTATION
        scene.camera = cam
    cam.data.ortho_scale = max(scene.render.resolution_x, scene.render.resolution_y) / PX_PER_UNIT
    forward = cam.rotation_euler.to_matrix() @ Vector((0.0, 0.0, -1.0))
    cam.location = Vector(target) - forward * 12.0
    bpy.context.view_layer.update()


def pixel_of(point):
    """Pixel da foto (x da esquerda, y de cima) onde cai o ponto 3D."""
    scene = bpy.context.scene
    co = world_to_camera_view(scene, scene.camera, Vector(point))
    return [co.x * scene.render.resolution_x, (1.0 - co.y) * scene.render.resolution_y]


def shoot(name, anchor_point, work_dir):
    """Fotografa, recorta pelo que aparece e grava em art/sprites; devolve a âncora no recorte."""
    os.makedirs(work_dir, exist_ok=True)
    path = os.path.join(work_dir, name + ".png")
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return crop_into_game(path, name, pixel_of(anchor_point))


def crop_into_game(path, name, anchor):
    image = bpy.data.images.load(path, check_existing=False)
    width, height = image.size
    pixels = np.array(image.pixels[:], dtype=np.float32).reshape(height, width, 4)[::-1]
    bpy.data.images.remove(image)
    alpha = pixels[:, :, 3]
    alpha[alpha < MIN_ALPHA] = 0.0
    rows = np.where(alpha.max(axis=1) > 0)[0]
    cols = np.where(alpha.max(axis=0) > 0)[0]
    if len(rows) == 0:
        rows = cols = np.array([0, 1])
    y0, y1 = max(rows[0] - CROP_PAD, 0), min(rows[-1] + CROP_PAD + 1, height)
    x0, x1 = max(cols[0] - CROP_PAD, 0), min(cols[-1] + CROP_PAD + 1, width)
    crop = pixels[y0:y1, x0:x1]
    out = bpy.data.images.new(name, x1 - x0, y1 - y0, alpha=True)
    out.pixels = crop[::-1].ravel()
    out.filepath_raw = os.path.join(SPRITES, name + ".png")
    out.file_format = "PNG"
    out.save()
    bpy.data.images.remove(out)
    return [round(anchor[0] - x0, 2), round(anchor[1] - y0, 2)]


def update_manifest(anchors, change=None):
    """Grava as âncoras novas no sprites.json (e o que [change] mudar no manifesto), com fim de linha LF."""
    path = os.path.join(SPRITES, "sprites.json")
    with open(path, encoding="utf-8") as source:
        manifest = json.load(source)
    for name, anchor in anchors.items():
        manifest["sprites"].setdefault(name, {})["anchor"] = anchor
    if change is not None:
        change(manifest)
    with open(path, "w", encoding="utf-8", newline="\n") as out:
        json.dump(manifest, out, ensure_ascii=False, indent=1)
        out.write("\n")
