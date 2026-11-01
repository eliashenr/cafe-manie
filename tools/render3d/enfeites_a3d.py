"""Enfeites, máquinas e fogões de evento na linguagem da referência A (DT-095): cada item mantém o nome, a coleção e o
caráter, com modelo novo e a luz quente do salão.

Uso (na pasta do projeto):
    C:/Blender/blender-5.2.3-windows-x64/blender.exe -b -P tools/render3d/enfeites_a3d.py -- [ids...] [rascunho] [prova]

Sem ids, faz todos. "prova" faz só uma vista de cada, para conferir a forma antes de fazer todos os quadros.

Grava em art/sprites com os mesmos nomes de sprite, então os ids, os preços e o save não mudam. Os fogões de evento seguem
as medidas de cozinha_a3d.py (panela e forno aceso) e o balcão de entregas, a altura do balcão (pilha de pratos).
"""
import json
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cena3d  # noqa: E402
from cena3d import aim_camera  # noqa: E402
import moveis3d as M  # noqa: E402
from moveis3d import box, cylinder, emission, solid, sphere, tube  # noqa: E402
from enfeites3d import cone, foliage, glass, leaf, rosette, torus  # noqa: E402
from amostra_a3d import brushed_steel, cast_iron, grain_wood, rich_wood, stone_top, taper  # noqa: E402
from assentos_a3d import chrome_a, gold, lathe, mirror_glass, veined_marble, velvet  # noqa: E402
import cozinha_a3d as K  # noqa: E402
from cozinha_a3d import disc, enamel, range_stove  # noqa: E402

WORK = os.path.join(cena3d.ROOT, "tools", "render3d", "out_enfeites_a")
SHADOW_MARGIN = 0.1
CABINET_H = 0.42               # o armário das máquinas
WALNUT = "#5d3820"
WARM = "#ffd9a0"


# --- Materiais ------------------------------------------------------------------------------------------------

def terracotta():
    return solid("#a9583a", 0.72)


def glaze(color):
    return solid(color, 0.2, 0.0, 0.7)


def wood(color, gloss=0.3):
    return rich_wood(color, 9.0, gloss)


def straw():
    """Palha: fios finos na vertical, com relevo."""
    key = ("straw",)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Palha")
        coords = nodes.new("ShaderNodeTexCoord")
        mapping = nodes.new("ShaderNodeMapping")
        mapping.inputs["Scale"].default_value = (70.0, 70.0, 5.0)
        links.new(coords.outputs["Object"], mapping.inputs["Vector"])
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Detail"].default_value = 6.0
        links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
        links.new(M._ramp(nodes, links, noise.outputs["Fac"], "#94702c", "#d9b65a", (0.35, 0.66)), bsdf.inputs["Base Color"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.8
        links.new(noise.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Roughness"].default_value = 0.9
        M._materials[key] = mat
    return M._materials[key]


def staves(color):
    """Aduelas do barril: tábuas na vertical, em volta."""
    key = ("staves", color)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Aduelas_" + color)
        coords = nodes.new("ShaderNodeTexCoord")
        mapping = nodes.new("ShaderNodeMapping")
        mapping.inputs["Scale"].default_value = (10.0, 10.0, 0.6)
        links.new(coords.outputs["Object"], mapping.inputs["Vector"])
        voronoi = nodes.new("ShaderNodeTexVoronoi")
        links.new(mapping.outputs["Vector"], voronoi.inputs["Vector"])
        links.new(M._ramp(nodes, links, voronoi.outputs["Distance"], M._tint(color, 0.08), M._shade(color, 0.45), (0.3, 0.62)), bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.5
        bsdf.inputs["Coat Weight"].default_value = 0.2
        M._materials[key] = mat
    return M._materials[key]


# --- Peças ----------------------------------------------------------------------------------------------------

def prism(profile, width, mat, bevel=0.012):
    """Corpo de perfil: o polígono [(y, z)...], visto de lado, com a largura em X centrada em zero."""
    bm = bmesh.new()
    left = [bm.verts.new((-width / 2, y, z)) for y, z in profile]
    right = [bm.verts.new((width / 2, y, z)) for y, z in profile]
    bm.faces.new(left)
    bm.faces.new(right[::-1])
    count = len(profile)
    for i in range(count):
        j = (i + 1) % count
        bm.faces.new((left[j], left[i], right[i], right[j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("Perfil")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Perfil", mesh)
    bpy.context.scene.collection.objects.link(obj)
    return M._finish(obj, mat, bevel)


def ribbed_ball(radius, center, mat, ribs=10, depth=0.1, squash=0.86):
    """Esfera de gomos (a abóbora): o raio sobe e desce em volta."""
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, location=(0, 0, 0), segments=96, ring_count=48)
    obj = bpy.context.active_object
    for v in obj.data.vertices:
        angle = math.atan2(v.co.y, v.co.x)
        factor = radius * (1.0 - depth + depth * abs(math.cos(ribs * angle / 2)) ** 0.6)
        v.co = Vector((v.co.x * factor, v.co.y * factor, v.co.z * radius * squash))
    obj.location = center
    return M._finish(obj, mat)


def pot(radius, height, mat):
    """Vaso torneado: base mais estreita, corpo e aba grossa, com a terra."""
    r = radius
    return [lathe([(0.0, 0.0), (r * 0.66, 0.0), (r * 0.72, 0.02), (r * 0.94, height * 0.82), (r * 1.08, height * 0.84), (r * 1.1, height), (r * 0.92, height), (r * 0.92, height - 0.03), (0.0, height - 0.03)], mat),
            cylinder(r * 0.92, height - 0.04, height - 0.012, solid("#2e2118", 0.95))]


def planter_box(radius, height, mat):
    """Caixote de madeira com cintas, para as árvores de fruta."""
    side = radius * 2
    iron = cast_iron("#2d2e33")
    return [box((side, side, height), (0.0, 0.0, height / 2), mat, 0.012),
            box((side + 0.012, side + 0.012, 0.022), (0.0, 0.0, height * 0.2), iron, 0.004),
            box((side + 0.012, side + 0.012, 0.022), (0.0, 0.0, height * 0.82), iron, 0.004),
            box((side - 0.03, side - 0.03, 0.01), (0.0, 0.0, height + 0.002), solid("#2e2118", 0.95), 0.0)]


def crown(blobs, color, seed, leaves=70, leaf_len=0.11, leaf_wid=0.042):
    """Copa: o miolo escuro e folhas soltas na superfície, viradas para fora."""
    rnd = random.Random(seed)
    inner = solid(M._shade(color, 0.5), 0.8)
    outer = [solid(M._tint(color, 0.05), 0.6), solid(color, 0.6), solid(M._shade(color, 0.14), 0.6)]
    parts = []
    for x, y, z, r in blobs:
        parts.append(sphere(r * 0.92, (x, y, z), inner))
    for i in range(leaves):
        x, y, z, r = blobs[i % len(blobs)]
        v = Vector((rnd.gauss(0, 1), rnd.gauss(0, 1), rnd.gauss(0.2, 1))).normalized()
        base = Vector((x, y, z)) + v * r * 0.88
        parts.append(leaf(base, v + Vector((rnd.uniform(-0.6, 0.6), rnd.uniform(-0.6, 0.6), 0.2)), leaf_len, leaf_wid, outer[i % 3]))
    return parts


def fruit_on(blobs, count, seed, build):
    """Espalha as frutas na superfície da copa."""
    rnd = random.Random(seed)
    parts = []
    for i in range(count):
        x, y, z, r = blobs[i % len(blobs)]
        v = Vector((rnd.gauss(0, 1), rnd.gauss(0, 1) - 0.6, rnd.gauss(0, 0.8))).normalized()
        parts.append(build(Vector((x, y, z)) + v * r * 1.02))
    return parts


def crooked(points, radius, mat):
    """Tronco torto, afinando, com as juntas arredondadas."""
    parts = []
    for i, (a, b) in enumerate(zip(points, points[1:])):
        width = radius * (1 - 0.16 * i)
        parts.append(tube(a, b, width, mat))
        parts.append(sphere(width, b, mat))
    return parts


def lamp_core(center, radius=0.04, strength=14.0, color="#ffd27a"):
    return sphere(radius, center, emission(color, strength))


def spoked_wheel(x, y, z, radius, rim, spoke, spokes=8, facing_y=True):
    """Roda de pé, virada para Y: aro, raios e cubo."""
    rot = (math.radians(90), 0, 0) if facing_y else (0, math.radians(90), 0)
    parts = [torus(radius, radius * 0.1, (x, y, z), rim, rot), torus(radius * 0.22, radius * 0.1, (x, y, z), rim, rot)]
    for i in range(spokes):
        a = 2 * math.pi * i / spokes
        if facing_y:
            end = (x + math.cos(a) * radius, y, z + math.sin(a) * radius)
        else:
            end = (x, y + math.cos(a) * radius, z + math.sin(a) * radius)
        parts.append(tube((x, y, z), end, radius * 0.05, spoke))
    return parts


# --- Plantas --------------------------------------------------------------------------------------------------

def plant_pot():
    green = foliage("#3d7f3f")
    parts = pot(0.2, 0.3, terracotta())
    parts += rosette((0, 0, 0.28), 10, 0.52, 0.085, 46, green, droop=0.28)
    parts += rosette((0, 0, 0.28), 7, 0.46, 0.08, 18, green, phase=0.45)
    return parts


def banana_tree():
    parts = pot(0.22, 0.3, terracotta())
    stem = solid("#74803c", 0.55)
    parts.append(lathe([(0.06, 0.28), (0.052, 0.55), (0.04, 0.86), (0.0, 0.9)], stem))
    for z in (0.42, 0.56, 0.7):
        parts.append(torus(0.05, 0.006, (0, 0, z), solid("#566030", 0.6)))
    parts += rosette((0, 0, 0.86), 8, 0.66, 0.1, 62, foliage("#3f8f3a"), droop=0.42)
    parts += rosette((0, 0, 0.88), 4, 0.5, 0.085, 26, foliage("#4f9f3f"), phase=0.4)
    for row in range(3):
        for i in range(4):
            a = i * math.pi / 3 - 1.1
            z = 0.68 - row * 0.055
            parts.append(sphere(0.02, (0.04 + math.cos(a) * 0.05, -0.06 + math.sin(a) * 0.05, z), solid("#e4c044", 0.5), (1, 1, 2.6)))
    return parts


def bonsai():
    base = wood("#3a2214", 0.5)
    parts = [box((0.56, 0.56, 0.12), (0, 0, 0.1), base, 0.012)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(box((0.07, 0.07, 0.05), (sx * 0.22, sy * 0.22, 0.025), base, 0.006))
    parts.append(lathe([(0.0, 0.16), (0.2, 0.16), (0.27, 0.24), (0.27, 0.255), (0.24, 0.255), (0.24, 0.24), (0.0, 0.24)], glaze("#23457f")))
    bark = wood("#4d3522", 0.05)
    parts += crooked([(0, 0, 0.24), (0.08, 0.03, 0.36), (-0.04, -0.02, 0.5), (0.05, 0.0, 0.62)], 0.04, bark)
    parts += crooked([(0.05, 0.01, 0.42), (0.2, 0.02, 0.48)], 0.018, bark)
    parts += crooked([(-0.03, -0.01, 0.48), (-0.18, 0.02, 0.56)], 0.018, bark)
    for x, y, z, r, s in [(0.21, 0.02, 0.5, 0.11, 0.55), (-0.2, 0.02, 0.59, 0.12, 0.55), (0.04, 0.0, 0.69, 0.15, 0.6)]:
        parts.append(sphere(r, (x, y, z), foliage("#3a7a3a"), (1.25, 1.25, s)))
    return parts


def cactus():
    from_pot = pot(0.19, 0.24, glaze("#f0e8d8"))
    for z in (0.09, 0.15):
        from_pot.append(torus(0.17 + (z - 0.09) * 0.45, 0.009, (0, 0, z), glaze("#234fa8")))
    skin = solid("#3a7a4a", 0.55)

    def ribbed(radius, z0, z1, center=(0.0, 0.0)):
        bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=z1 - z0, location=(center[0], center[1], (z0 + z1) / 2), vertices=10)
        return [M._finish(bpy.context.active_object, skin, 0.012), sphere(radius * 1.0, (center[0], center[1], z1), skin)]
    parts = from_pot + ribbed(0.1, 0.22, 0.86)
    for side, z, h in ((-1, 0.42, 0.22), (1, 0.52, 0.2)):
        parts.append(tube((side * 0.08, 0, z), (side * 0.2, 0, z), 0.055, skin))
        parts.append(sphere(0.055, (side * 0.2, 0, z), skin))
        parts += ribbed(0.055, z, z + h, (side * 0.2, 0.0))
    for a in range(5):
        rad = a * 2 * math.pi / 5
        parts.append(sphere(0.026, (math.cos(rad) * 0.03, math.sin(rad) * 0.03, 0.955), solid("#d94a7f", 0.5)))
    parts.append(sphere(0.02, (0, 0, 0.965), solid("#e8bd38", 0.5)))
    return parts


def olive_tree():
    parts = pot(0.23, 0.3, terracotta())
    bark = wood("#6d5c46", 0.05)
    parts += crooked([(0, 0, 0.28), (0.06, 0.02, 0.5), (-0.03, 0.0, 0.72)], 0.05, bark)
    parts += crooked([(0.04, 0.01, 0.56), (0.18, -0.03, 0.74)], 0.022, bark)
    parts += crooked([(-0.02, 0.0, 0.62), (-0.17, 0.05, 0.78)], 0.022, bark)
    blobs = [(0.0, 0.0, 0.95, 0.2), (-0.18, 0.05, 0.85, 0.16), (0.2, -0.04, 0.86, 0.16)]
    parts += crown(blobs, "#7d9460", 7, 260, 0.09, 0.024)
    parts += fruit_on(blobs, 12, 11, lambda p: sphere(0.016, p, solid("#2d2b22", 0.25, 0.0, 0.6), (1, 1, 1.3)))
    return parts


def macrame_plant():
    frame = wood("#8c5526", 0.25)
    rope = solid("#e4d4b4", 0.9)
    parts = []
    for a in range(3):
        rad = 2 * math.pi * a / 3 + 0.5
        parts.append(taper((math.cos(rad) * 0.34, math.sin(rad) * 0.34, 0.0), (0, 0, 1.3), 0.024, 0.016, frame))
    parts += [sphere(0.03, (0, 0, 1.3), frame), tube((0, 0, 1.3), (0, 0, 1.12), 0.006, rope)]
    z = 0.62
    for a in range(5):
        rad = 2 * math.pi * a / 5
        low = (math.cos(rad) * 0.15, math.sin(rad) * 0.15, z + 0.1)
        parts.append(tube(low, (0, 0, 1.12), 0.005, rope))
        parts.append(tube(low, (0, 0, z - 0.03), 0.005, rope))
    parts.append(sphere(0.022, (0, 0, 1.12), rope))
    for p in pot(0.15, 0.16, glaze("#c9744a")):
        p.location.z += z
        parts.append(p)
    parts += rosette((0, 0, z + 0.14), 12, 0.36, 0.05, 72, foliage("#4a8f3f"), droop=0.8)
    parts += rosette((0, 0, z + 0.14), 6, 0.2, 0.05, 20, foliage("#4a8f3f"), phase=0.3)
    return parts


def succulents():
    parts = [box((0.8, 0.46, 0.2), (0, 0, 0.2), wood("#a56c3a", 0.2), 0.012), box((0.76, 0.42, 0.01), (0, 0, 0.3), solid("#3a2c20", 0.95), 0.0)]
    for x in (-0.32, 0.32):
        parts.append(tube((x, -0.14, 0.0), (x * 0.86, -0.14, 0.11), 0.012, cast_iron()))
        parts.append(tube((x, 0.14, 0.0), (x * 0.86, 0.14, 0.11), 0.012, cast_iron()))
    for i, (x, y, color) in enumerate(((-0.25, -0.03, "#79b598"), (0.0, 0.05, "#92bb74"), (0.25, -0.04, "#7f9fb2"))):
        parts += rosette((x, y, 0.305), 11, 0.13, 0.042, 62, solid(color, 0.5), phase=i)
        parts += rosette((x, y, 0.31), 8, 0.095, 0.036, 38, solid(M._tint(color, 0.14), 0.5), phase=i + 0.3)
        parts += rosette((x, y, 0.315), 5, 0.06, 0.028, 14, solid(M._tint(color, 0.3), 0.5), phase=i + 0.6)
    return parts


def _fruit_tree(leaf_color, seed, count, build):
    parts = planter_box(0.22, 0.28, wood("#7d532d", 0.15))
    parts += crooked([(0, 0, 0.28), (0.02, 0.0, 0.48), (-0.01, 0.01, 0.7)], 0.04, wood("#5d432a", 0.05))
    blobs = [(0.0, 0.0, 0.92, 0.25), (-0.2, 0.06, 0.8, 0.18), (0.2, -0.05, 0.82, 0.19), (0.04, -0.16, 0.76, 0.16)]
    parts += crown(blobs, leaf_color, seed, 240)
    parts += fruit_on(blobs, count, seed + 1, build)
    return parts


def tree_blueberry():
    fruit = solid("#2f3a7f", 0.3, 0.0, 0.4)
    return _fruit_tree("#3d7f4a", 3, 26, lambda p: sphere(0.026, p, fruit))


def tree_mango():
    fruit = solid("#e8922a", 0.35, 0.0, 0.4)
    return _fruit_tree("#3f8a3f", 5, 12, lambda p: sphere(0.05, p, fruit, (1, 1, 1.3)))


def tree_strawberry():
    fruit = solid("#c8283a", 0.3, 0.0, 0.5)
    return _fruit_tree("#459040", 9, 18, lambda p: sphere(0.036, p, fruit, (1, 1, 1.28)))


def flower_vase():
    parts = [lathe([(0.0, 0.0), (0.13, 0.0), (0.14, 0.02), (0.09, 0.08), (0.17, 0.3), (0.13, 0.5), (0.07, 0.6), (0.09, 0.65), (0.0, 0.64)], glaze("#23457f"))]
    parts.append(torus(0.17, 0.008, (0, 0, 0.3), gold()))
    rnd = random.Random(4)
    stem = solid("#3f7a3c", 0.6)
    for i in range(11):
        a = i * 2.3
        r = 0.06 + 0.05 * (i % 3)
        top = (math.cos(a) * r, math.sin(a) * r, 0.86 + 0.06 * (i % 3))
        parts.append(tube((0, 0, 0.62), top, 0.005, stem))
        color = ("#d8344a", "#e8bd38", "#f8f1e4", "#e07a2e", "#a65fc7")[i % 5]
        for petal in range(6):
            rad = petal * math.pi / 3 + rnd.random()
            parts.append(sphere(0.026, (top[0] + math.cos(rad) * 0.03, top[1] + math.sin(rad) * 0.03, top[2]), solid(color, 0.6), (1, 1, 0.5)))
        parts.append(sphere(0.016, (top[0], top[1], top[2] + 0.008), solid("#d9a42e", 0.6)))
    parts += [leaf((0, 0, 0.64), (math.cos(a), math.sin(a), 0.7), 0.26, 0.05, solid("#3f7a3c", 0.6)) for a in (0.6, 2.4, 4.4)]
    return parts


# --- Luminárias e placas --------------------------------------------------------------------------------------

def floor_lamp():
    brass = gold()
    parts = []
    for a in range(3):
        rad = 2 * math.pi * a / 3 + 0.5
        parts.append(taper((math.cos(rad) * 0.26, math.sin(rad) * 0.26, 0.0), (0, 0, 1.08), 0.012, 0.02, wood(WALNUT, 0.4)))
    parts.append(cylinder(0.04, 1.06, 1.1, brass))
    parts.append(lathe([(0.2, 1.1), (0.15, 1.38), (0.145, 1.38), (0.195, 1.1)], emission("#ffc98a", 0.7), vertices=48))
    parts.append(lamp_core((0, 0, 1.2), 0.05, 10.0))
    return parts


def edison_lamp():
    iron = cast_iron("#25262b")
    parts = [lathe([(0.0, 0.0), (0.16, 0.0), (0.16, 0.024), (0.05, 0.05), (0.02, 0.09), (0.0, 0.09)], iron)]
    parts += [tube((0, 0, 0.09), (0, 0, 1.3), 0.016, iron), sphere(0.024, (0, 0, 0.7), iron), sphere(0.024, (0, 0, 1.3), iron),
              tube((0, 0, 1.3), (0.26, 0, 1.36), 0.014, iron), sphere(0.02, (0.26, 0, 1.36), iron), tube((0.26, 0, 1.36), (0.26, 0, 1.22), 0.007, solid("#14141a", 0.5))]
    parts.append(cylinder(0.024, 1.18, 1.23, gold(), (0.26, 0.0)))
    parts.append(sphere(0.062, (0.26, 0, 1.1), glass("#ffe8b0", 0.4), (1, 1, 1.25)))
    parts.append(sphere(0.02, (0.26, 0, 1.1), emission("#ffb24d", 24.0), (1, 1, 1.8)))
    return parts


def paper_lantern():
    frame = wood("#2c1a10", 0.4)
    parts = [box((0.32, 0.32, 0.05), (0, 0, 0.025), frame, 0.006), box((0.05, 0.05, 1.4), (0, 0, 0.72), frame, 0.006),
             box((0.42, 0.05, 0.05), (0.15, 0, 1.42), frame, 0.006), tube((0.3, 0, 1.4), (0.3, 0, 1.3), 0.004, frame)]
    profile = [(0.02, 0.9), (0.1, 0.92), (0.15, 1.0), (0.165, 1.1), (0.15, 1.2), (0.1, 1.28), (0.02, 1.3)]
    parts.append(lathe([(r, z) for r, z in profile], emission("#d9402f", 1.6), (0.3, 0.0)))
    for z in (0.96, 1.03, 1.1, 1.17, 1.24):
        radius = 0.165 * math.sqrt(max(0.05, 1 - ((z - 1.1) / 0.2) ** 2))
        parts.append(torus(radius, 0.003, (0.3, 0, z), solid("#6e1d16", 0.6)))
    parts += [cylinder(0.075, 1.28, 1.31, frame, (0.3, 0.0)), cylinder(0.075, 0.89, 0.92, frame, (0.3, 0.0))]
    for x in (-0.012, 0.012):
        parts.append(tube((0.3 + x, 0, 0.89), (0.3 + x, 0, 0.74), 0.004, solid("#c8a038", 0.6)))
    return parts


def paris_lamp():
    iron = solid("#1d3329", 0.4, 0.5)
    parts = [lathe([(0.0, 0.0), (0.2, 0.0), (0.2, 0.03), (0.13, 0.08), (0.1, 0.22), (0.05, 0.3), (0.04, 0.6), (0.03, 1.2), (0.0, 1.2)], iron)]
    for z in (0.3, 0.6, 0.9):
        parts.append(torus(0.044, 0.01, (0, 0, z), iron))
    for side in (-1, 1):
        x = side * 0.2
        parts.append(tube((0, 0, 1.12), (x, 0, 1.2), 0.012, iron))
        parts.append(torus(0.05, 0.008, (side * 0.09, 0, 1.08), iron, (math.radians(90), 0, 0)))
        parts.append(lathe([(0.05, 1.2), (0.09, 1.38), (0.085, 1.38), (0.045, 1.2)], glass(WARM, 0.3), (x, 0.0)))
        parts.append(lamp_core((x, 0, 1.28), 0.032, 16.0))
        parts.append(lathe([(0.1, 1.38), (0.04, 1.47), (0.012, 1.5), (0.0, 1.5)], iron, (x, 0.0)))
    return parts


def neon_diner():
    chrome = chrome_a()
    parts = [lathe([(0.0, 0.0), (0.16, 0.0), (0.16, 0.024), (0.05, 0.05), (0.02, 0.09), (0.0, 0.09)], chrome), tube((0, 0, 0.09), (0, 0, 0.88), 0.018, chrome)]
    parts.append(box((0.74, 0.07, 0.3), (0, 0, 1.04), solid("#15151f", 0.28, 0.0, 0.5), 0.02))
    for z in (0.88, 1.2):
        parts.append(box((0.76, 0.08, 0.016), (0, 0, z), chrome, 0.004))
    for x in (-0.37, 0.37):
        parts.append(box((0.016, 0.08, 0.33), (x, 0, 1.04), chrome, 0.004))
    for i in range(9):
        parts.append(sphere(0.012, (-0.32 + i * 0.08, -0.04, 1.165), emission("#ffd27a", 10.0)))
        parts.append(sphere(0.012, (-0.32 + i * 0.08, -0.04, 0.915), emission("#ffd27a", 10.0)))
    bpy.ops.object.text_add(location=(0, -0.038, 0.985), rotation=(math.radians(90), 0, 0))
    text = bpy.context.active_object
    text.data.body = "DINER"
    text.data.align_x = "CENTER"
    text.data.size = 0.16
    text.data.extrude = 0.004
    text.data.materials.append(emission("#ff4dd2", 7.0))
    parts.append(text)
    return parts


def station_clock():
    green = solid("#1f4a35", 0.38, 0.4)
    brass = gold()
    parts = [lathe([(0.0, 0.0), (0.2, 0.0), (0.2, 0.04), (0.13, 0.08), (0.09, 0.3), (0.05, 0.36), (0.045, 1.0), (0.09, 1.04), (0.0, 1.04)], green)]
    parts += [torus(0.05, 0.012, (0, 0, 0.36), brass), torus(0.05, 0.012, (0, 0, 0.7), brass)]
    y = 0.0
    rot = (math.radians(90), 0, math.radians(45))
    bpy.ops.mesh.primitive_cylinder_add(radius=0.2, depth=0.1, location=(0, y, 1.24), rotation=rot, vertices=64)
    parts.append(M._finish(bpy.context.active_object, green, 0.012))
    normal = Vector((0.7071, -0.7071, 0.0))
    for side in (1, -1):
        c = Vector((0, 0, 1.24)) + normal * side * 0.052
        bpy.ops.mesh.primitive_cylinder_add(radius=0.17, depth=0.004, location=c, rotation=rot, vertices=64)
        parts.append(M._finish(bpy.context.active_object, solid("#f6efe0", 0.4), 0.0))
        parts.append(torus(0.172, 0.01, c, brass, rot))
        right = Vector((normal.y, -normal.x, 0.0))
        dark = solid("#1c1c20", 0.5)
        for hour in range(12):
            a = hour * math.pi / 6
            mark = c + normal * side * 0.003 + (right * math.cos(a) + Vector((0, 0, 1)) * math.sin(a)) * 0.145
            parts.append(sphere(0.01, mark, dark, (1, 1, 1)))
        tip = normal * side * 0.006
        parts.append(tube(c + tip, c + tip + Vector((0, 0, 0.11)), 0.006, dark))
        parts.append(tube(c + tip, c + tip + right * 0.08, 0.006, dark))
    parts.append(sphere(0.03, (0, 0, 1.46), brass))
    return parts


# --- Brinquedos, música e festa -------------------------------------------------------------------------------

def arcade():
    """Gabinete de fliperama: perfil de verdade, com a tela inclinada, o painel de botões e a marquise acesa."""
    w = 0.66
    side = [(-0.3, 0.0), (0.34, 0.0), (0.34, 1.5), (-0.26, 1.5), (-0.3, 1.34), (-0.16, 1.26), (-0.22, 0.86), (-0.4, 0.76), (-0.4, 0.68), (-0.26, 0.62)]
    body = solid("#20307f", 0.3, 0.0, 0.5)
    parts = [prism(side, w, body, 0.012)]
    parts.append(prism([(-0.24, 1.26), (-0.17, 1.27), (-0.23, 0.87), (-0.29, 0.86)], w - 0.08, solid("#0a0c14", 0.2), 0.002))
    screen = prism([(-0.25, 1.24), (-0.235, 1.24), (-0.29, 0.89), (-0.305, 0.89)], w - 0.14, emission("#2f9fe0", 2.0), 0.0)
    parts.append(screen)
    parts.append(prism([(-0.36, 1.46), (-0.24, 1.46), (-0.24, 1.34), (-0.36, 1.34)], w - 0.04, emission("#ff4dd2", 2.4), 0.002))
    parts.append(prism([(-0.41, 0.77), (-0.23, 0.87), (-0.23, 0.85), (-0.41, 0.74)], w - 0.03, solid("#d8326e", 0.3, 0.0, 0.6), 0.002))
    z = 0.8
    for x, color in ((-0.14, "#e7b632"), (-0.03, "#e23f4f"), (0.08, "#2bb8d6"), (0.18, "#7fd040")):
        parts.append(sphere(0.024, (x, -0.33, z), solid(color, 0.28, 0.0, 0.7), (1, 1, 0.5)))
    parts.append(tube((-0.24, -0.33, z), (-0.24, -0.33, z + 0.07), 0.009, chrome_a()))
    parts.append(sphere(0.022, (-0.24, -0.33, z + 0.08), solid("#d8326e", 0.28, 0.0, 0.7)))
    parts.append(box((0.26, 0.012, 0.2), (0.0, -0.308, 0.3), solid("#101018", 0.35), 0.003))
    parts.append(box((0.04, 0.006, 0.06), (0.0, -0.316, 0.34), emission("#ffb24d", 3.0), 0.0))
    for sign in (-1, 1):
        parts.append(box((0.008, 0.6, 0.014), (sign * (w / 2 + 0.001), 0.02, 1.3), emission("#3ee0ff", 3.0), 0.0))
    return parts


def claw_machine():
    chrome = chrome_a()
    body = enamel("#a8232f")
    parts = [box((0.76, 0.76, 0.5), (0, 0, 0.25), body, 0.016), box((0.78, 0.78, 0.03), (0, 0, 0.5), chrome, 0.006)]
    parts.append(box((0.4, 0.14, 0.05), (-0.03, -0.4, 0.44), enamel("#23232b"), 0.008))
    parts += [tube((-0.14, -0.4, 0.46), (-0.14, -0.4, 0.54), 0.008, chrome), sphere(0.024, (-0.14, -0.4, 0.55), enamel("#e7b632")), sphere(0.024, (0.07, -0.4, 0.475), enamel("#2bb8d6"), (1, 1, 0.5))]
    parts.append(box((0.28, 0.01, 0.2), (0.0, -0.385, 0.2), solid("#0e0e14", 0.3), 0.003))
    parts.append(box((0.72, 0.72, 0.62), (0, 0, 0.82), glass("#e4f5fb", 0.14), 0.006))
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(box((0.03, 0.03, 0.62), (sx * 0.365, sy * 0.365, 0.82), chrome, 0.004))
    colors = ("#d98aa5", "#e7b632", "#6fb3dd", "#7fc46a", "#c47ad0")
    rnd = random.Random(2)
    for i in range(16):
        a = rnd.uniform(0, 6.28)
        r = rnd.uniform(0.04, 0.27)
        z = 0.57 + (i % 3) * 0.055
        x, y = math.cos(a) * r, math.sin(a) * r
        c = solid(colors[i % 5], 0.85)
        parts.append(sphere(0.06, (x, y, z), c))
        for s in (-1, 1):
            parts.append(sphere(0.02, (x + s * 0.035, y, z + 0.055), c))
    parts.append(box((0.8, 0.8, 0.18), (0, 0, 1.22), enamel("#a8232f"), 0.016))
    parts.append(box((0.82, 0.82, 0.03), (0, 0, 1.14), emission("#ffd27a", 3.0), 0.004))
    claw = chrome
    parts += [tube((0.0, 0.0, 1.13), (0.0, 0.0, 0.92), 0.006, claw), cylinder(0.035, 0.88, 0.93, claw)]
    for a in (0.5, 2.6, 4.7):
        tip = (math.cos(a) * 0.075, math.sin(a) * 0.075, 0.76)
        mid = (math.cos(a) * 0.095, math.sin(a) * 0.095, 0.83)
        parts += [tube((0, 0, 0.88), mid, 0.007, claw), tube(mid, tip, 0.007, claw)]
    return parts


def jukebox():
    """Jukebox dos anos 50: a arca redonda, as colunas de luz e a vitrine dos discos."""
    arc = []
    for i in range(25):
        a = math.pi * i / 24
        arc.append((math.cos(a) * 0.34, 0.86 + math.sin(a) * 0.42))
    wood_mat = wood("#6e3d1f", 0.6)
    prof = [(0.34, 0.0), (0.34, 0.86)] + arc + [(-0.34, 0.86), (-0.34, 0.0)]
    # O perfil é visto de frente: a largura vira X e a espessura, Y.
    bm = bmesh.new()
    depth = 0.5
    front = [bm.verts.new((x, -depth / 2, z)) for x, z in prof]
    back = [bm.verts.new((x, depth / 2, z)) for x, z in prof]
    bm.faces.new(front)
    bm.faces.new(back[::-1])
    for i in range(len(prof)):
        j = (i + 1) % len(prof)
        bm.faces.new((front[i], front[j], back[j], back[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("Arca")
    bm.to_mesh(mesh)
    bm.free()
    body = bpy.data.objects.new("Arca", mesh)
    bpy.context.scene.collection.objects.link(body)
    parts = [M._finish(body, wood_mat, 0.016)]
    y = -depth / 2 - 0.005
    chrome = chrome_a()
    for i in range(25):
        a = math.pi * i / 24
        if i < 24:
            b = math.pi * (i + 1) / 24
            parts.append(tube((math.cos(a) * 0.3, y, 0.86 + math.sin(a) * 0.38), (math.cos(b) * 0.3, y, 0.86 + math.sin(b) * 0.38), 0.022, emission("#ff8a3d", 3.0)))
            parts.append(tube((math.cos(a) * 0.25, y, 0.86 + math.sin(a) * 0.33), (math.cos(b) * 0.25, y, 0.86 + math.sin(b) * 0.33), 0.012, chrome))
    for x in (-0.3, 0.3):
        parts.append(tube((x, y, 0.08), (x, y, 0.86), 0.022, emission("#ff8a3d", 3.0)))
    parts.append(box((0.42, 0.01, 0.24), (0, y, 0.92), emission("#fff0c8", 1.0), 0.004))
    parts.append(box((0.42, 0.012, 0.03), (0, y - 0.004, 0.8), chrome, 0.003))
    for i in range(8):
        parts.append(disc(0.012, -0.14 + i * 0.04, y - 0.01, 0.75, enamel(("#d8344a", "#e7b632")[i % 2]), 0.01))
    for i in range(9):
        parts.append(box((0.022, 0.012, 0.42), (-0.2 + i * 0.05, y, 0.36), chrome if i % 2 else emission("#6fd0e8", 1.6), 0.002))
    parts.append(box((0.48, 0.012, 0.022), (0, y - 0.002, 0.59), chrome, 0.003))
    parts.append(box((0.48, 0.012, 0.022), (0, y - 0.002, 0.13), chrome, 0.003))
    return parts


def boombox():
    crate = wood("#a56c3a", 0.1)
    parts = []
    for z in (0.04, 0.15, 0.26):
        for sx in (-1, 1):
            parts.append(box((0.018, 0.52, 0.085), (sx * 0.29, 0.0, z), crate, 0.003))
        for sy in (-1, 1):
            parts.append(box((0.6, 0.018, 0.085), (0.0, sy * 0.25, z), crate, 0.003))
    parts.append(box((0.6, 0.52, 0.02), (0, 0, 0.31), crate, 0.003))
    z = 0.48
    body = solid("#1c1c22", 0.34, 0.0, 0.5)
    chrome = chrome_a()
    parts.append(box((0.72, 0.24, 0.32), (0, 0, z), body, 0.02))
    y = -0.122
    for x in (-0.22, 0.22):
        parts.append(disc(0.115, x, y, z - 0.01, chrome, 0.012))
        parts.append(disc(0.1, x, y - 0.004, z - 0.01, solid("#101014", 0.7), 0.01))
        parts.append(disc(0.04, x, y - 0.008, z - 0.01, chrome, 0.012))
    parts.append(box((0.2, 0.01, 0.1), (0, y, z + 0.08), emission("#4fd0ff", 2.0), 0.002))
    parts.append(box((0.2, 0.01, 0.13), (0, y, z - 0.05), solid("#2d2d35", 0.2, 0.0, 0.8), 0.002))
    for i in range(5):
        parts.append(box((0.03, 0.014, 0.018), (-0.08 + i * 0.04, y, z - 0.13), chrome, 0.002))
    for x in (-0.28, 0.28):
        parts.append(tube((x, 0, z + 0.16), (x, 0, z + 0.25), 0.012, chrome))
    parts.append(tube((-0.28, 0, z + 0.25), (0.28, 0, z + 0.25), 0.014, chrome))
    parts.append(tube((0.32, 0.06, z + 0.16), (0.42, 0.06, z + 0.5), 0.004, chrome))
    return parts


def disco_ball():
    chrome = chrome_a()
    parts = [lathe([(0.0, 0.0), (0.17, 0.0), (0.17, 0.024), (0.05, 0.05), (0.018, 0.09), (0.0, 0.09)], cast_iron("#25262b")), tube((0, 0, 0.09), (0, 0, 1.38), 0.015, chrome)]
    parts += [tube((0, 0, 1.38), (0.2, 0, 1.46), 0.012, chrome), tube((0.2, 0, 1.46), (0.2, 0, 1.32), 0.004, chrome)]
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.18, location=(0.2, 0, 1.14))
    parts.append(M._finish(bpy.context.active_object, mirror_glass(), smooth=False))
    return parts


def dj_booth():
    body = solid("#14141c", 0.28, 0.0, 0.6)
    parts = [box((1.86, 0.66, 0.72), (0, 0, 0.36), body, 0.02), box((1.92, 0.72, 0.04), (0, 0, 0.74), brushed_steel("#a9acad"), 0.008)]
    colors = ("#a06bff", "#4fa0ff", "#3ee0ff", "#3fd07a", "#ffd23f", "#ff8a2a", "#ff4d5e")
    for i, c in enumerate(colors):
        for j in range(4):
            parts.append(box((0.2, 0.008, 0.11), (-0.8 + i * 0.267, -0.334, 0.14 + j * 0.15), emission(c, 1.0 + j * 0.7), 0.002))
    for x in (-0.56, 0.56):
        parts.append(box((0.54, 0.46, 0.04), (x, 0, 0.78), solid("#26262e", 0.3, 0.3), 0.006))
        parts.append(cylinder(0.2, 0.8, 0.815, solid("#101014", 0.3, 0.0, 0.6), (x, 0.0)))
        parts.append(cylinder(0.05, 0.815, 0.82, enamel("#c8283a"), (x, 0.0)))
        parts.append(tube((x + 0.2, 0.18, 0.84), (x + 0.1, 0.02, 0.83), 0.006, chrome_a()))
    parts.append(box((0.36, 0.42, 0.05), (0, 0, 0.785), solid("#30303a", 0.3, 0.3), 0.006))
    for i in range(4):
        parts.append(box((0.018, 0.12, 0.012), (-0.1 + i * 0.066, -0.1, 0.815), chrome_a(), 0.002))
        parts.append(sphere(0.014, (-0.1 + i * 0.066, 0.1, 0.815), emission("#3ee0ff", 4.0)))
    parts.append(torus(0.09, 0.008, (0.0, 0.22, 0.86), solid("#101014", 0.3), (math.radians(90), 0, 0)))
    return parts


def balloons():
    parts = [lathe([(0.0, 0.0), (0.09, 0.0), (0.1, 0.02), (0.07, 0.07), (0.03, 0.09), (0.0, 0.09)], gold())]
    string = solid("#f4efe6", 0.5)
    for x, y, z, c in ((0.0, 0.02, 1.34, "#e7b632"), (-0.2, 0.06, 1.18, "#d8344a"), (0.2, -0.05, 1.16, "#2bb8d6"), (-0.07, -0.16, 1.02, "#a65fc7"), (0.15, 0.15, 0.98, "#3fa862"), (-0.22, -0.08, 0.86, "#e78fae")):
        parts.append(tube((0, 0, 0.09), (x, y, z - 0.17), 0.002, string))
        parts.append(sphere(0.15, (x, y, z), solid(c, 0.1, 0.0, 0.9), (1, 1, 1.2)))
        parts.append(cone(0.022, z - 0.2, z - 0.17, solid(c, 0.2), (x, y), top_radius=0.006))
    return parts


def party_cake():
    plate = solid("#f4efe4", 0.22, 0.0, 0.7)
    parts = [lathe([(0.0, 0.0), (0.2, 0.0), (0.21, 0.02), (0.05, 0.05), (0.035, 0.28), (0.08, 0.31), (0.34, 0.33), (0.34, 0.345), (0.0, 0.345)], plate)]
    parts.append(cylinder(0.28, 0.345, 0.52, solid("#e7a6bd", 0.5), bevel=0.02, vertices=64))
    parts.append(cylinder(0.2, 0.52, 0.68, solid("#f4ead8", 0.5), bevel=0.02, vertices=64))
    parts.append(cylinder(0.13, 0.68, 0.8, solid("#8fbfdd", 0.5), bevel=0.02, vertices=64))
    for radius, z, color, count in ((0.28, 0.52, "#fbf6ee", 30), (0.2, 0.68, "#e7a6bd", 22), (0.13, 0.8, "#fbf6ee", 16)):
        frosting = solid(color, 0.45)
        for i in range(count):
            a = 2 * math.pi * i / count
            parts.append(sphere(0.024, (math.cos(a) * radius, math.sin(a) * radius, z), frosting, (1, 1, 0.8)))
            if i % 3 == 0 and radius > 0.15:
                parts.append(sphere(0.016, (math.cos(a) * (radius + 0.003), math.sin(a) * (radius + 0.003), z - 0.05), frosting, (1, 0.7, 2.2)))
    for i in range(6):
        a = i * 2 * math.pi / 6
        x, y = math.cos(a) * 0.075, math.sin(a) * 0.075
        parts.append(cylinder(0.009, 0.8, 0.9, solid(("#d8344a", "#e7b632", "#2bb8d6")[i % 3], 0.4), (x, y)))
        parts.append(sphere(0.01, (x, y, 0.915), emission("#ffb13d", 20.0), (1, 1, 1.7)))
    return parts


def pinata():
    """Piñata de burrinho, de franjas coloridas, pendurada no suporte."""
    frame = wood("#8c5526", 0.25)
    parts = [box((0.42, 0.42, 0.04), (0, 0, 0.02), frame, 0.006), box((0.05, 0.05, 1.42), (-0.17, -0.0, 0.73), frame, 0.006),
             box((0.56, 0.05, 0.05), (0.08, 0, 1.46), frame, 0.006), tube((0.2, 0, 1.44), (0.2, 0, 1.12), 0.004, solid("#e4d4b4", 0.9))]
    colors = ("#d8344a", "#e7b632", "#2d9a63", "#2bb8d6", "#a65fc7", "#e07a2e")
    z = 0.96
    for i in range(8):   # o corpo, em anéis de franja
        x = 0.04 + i * 0.05
        ring = sphere(0.1 + 0.018 * math.sin(i / 7 * math.pi), (x, 0, z), solid(colors[i % 6], 0.85), (0.34, 1.0, 1.0))
        parts.append(ring)
    for i in range(4):   # pescoço e cabeça
        parts.append(sphere(0.07, (0.4 + i * 0.012, 0, z + 0.08 + i * 0.05), solid(colors[(i + 3) % 6], 0.85), (1, 1, 0.45)))
    parts.append(sphere(0.085, (0.47, 0, z + 0.28), solid("#d8344a", 0.85), (1.3, 0.8, 0.75)))
    for side in (-1, 1):
        parts.append(leaf((0.42, side * 0.04, z + 0.32), (-0.2, side * 0.2, 1), 0.13, 0.03, solid("#e7b632", 0.85)))
    parts.append(sphere(0.01, (0.53, -0.066, z + 0.31), solid("#101014", 0.2)))
    for x in (0.08, 0.34):
        for y in (-0.06, 0.06):
            parts.append(cylinder(0.03, z - 0.24, z - 0.07, solid(colors[int(x * 10) % 6], 0.85), (x, y)))
    for i in range(5):
        parts.append(leaf((0.03, 0, z + 0.04), (-1, 0, -0.2 - i * 0.18), 0.16, 0.012, solid(colors[i], 0.85)))
    return parts


def popcorn_cart():
    red = enamel("#a8232f")
    chrome = chrome_a()
    parts = [box((0.66, 0.5, 0.42), (0, 0, 0.42), red, 0.014), box((0.68, 0.52, 0.02), (0, 0, 0.64), chrome, 0.004), box((0.68, 0.52, 0.02), (0, 0, 0.21), chrome, 0.004)]
    for side in (-1, 1):
        parts += spoked_wheel(side * 0.0, side * 0.29, 0.17, 0.17, cast_iron("#25262b"), gold(), 10)
    parts.append(box((0.3, 0.012, 0.16), (0.0, -0.256, 0.42), enamel("#f4efe4"), 0.004))
    parts.append(box((0.62, 0.46, 0.46), (0, 0, 0.88), glass("#f4fbff", 0.14), 0.006))
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(box((0.022, 0.022, 0.48), (sx * 0.31, sy * 0.23, 0.88), gold(), 0.004))
    rnd = random.Random(8)
    kernel = [solid("#f8ebbd", 0.8), solid("#f2dc98", 0.8)]
    for i in range(70):
        parts.append(sphere(0.028, (rnd.uniform(-0.27, 0.27), rnd.uniform(-0.19, 0.19), 0.67 + rnd.random() ** 2 * 0.17), kernel[i % 2]))
    parts.append(lathe([(0.1, 1.0), (0.07, 0.93), (0.0, 0.92)], chrome))
    # O teto listrado, em duas águas.
    stripes = 8
    for i in range(stripes):
        x = -0.36 + (i + 0.5) * 0.09
        parts.append(prism([(-0.31, 1.11), (0.31, 1.11), (0.0, 1.27)], 0.09, enamel("#a8232f" if i % 2 else "#f4efe4"), 0.002))
        parts[-1].location.x = x
    return parts


def ring_toss():
    frame = wood("#7a4a26", 0.25)
    parts = [box((0.9, 0.7, 0.5), (0, 0, 0.25), enamel("#23479a"), 0.012), box((0.94, 0.74, 0.03), (0, 0, 0.515), frame, 0.006)]
    for i in range(4):
        parts.append(box((0.1, 0.012, 0.46), (-0.3 + i * 0.2, -0.356, 0.25), enamel("#f4efe4"), 0.002))
    for x in (-0.42, 0.42):
        parts.append(box((0.04, 0.04, 0.9), (x, 0.32, 0.95), frame, 0.006))
    parts.append(box((0.88, 0.03, 0.2), (0, 0.32, 1.32), enamel("#a8232f"), 0.008))
    for i in range(7):
        parts.append(sphere(0.012, (-0.36 + i * 0.12, 0.3, 1.32), emission("#ffd27a", 10.0)))
    for x, y, c in ((-0.26, 0.1, "#1f5a2d"), (-0.08, -0.14, "#5a1f7a"), (0.1, 0.12, "#7a1a24"), (0.28, -0.08, "#1f5a2d"), (-0.26, -0.2, "#7a1a24"), (0.1, -0.22, "#1f5a2d")):
        z = 0.53
        parts.append(lathe([(0.0, z), (0.04, z), (0.042, z + 0.02), (0.042, z + 0.14), (0.014, z + 0.2), (0.012, z + 0.27), (0.0, z + 0.27)], solid(c, 0.08, 0.0, 1.0)))
    for x, y, c in ((-0.08, -0.14, "#e7b632"), (0.28, -0.08, "#2bb8d6")):
        parts.append(torus(0.075, 0.012, (x, y, 0.56), solid(c, 0.35)))
    return parts


def stage():
    """Palco de tábuas com a cortina de veludo atrás, as caixas de som e o microfone."""
    deck = grain_wood("#8c5a30", 0.4)
    parts = [box((1.94, 1.94, 0.2), (0, 0, 0.1), wood("#4c2d18", 0.2), 0.012), box((1.98, 1.98, 0.03), (0, 0, 0.215), deck, 0.006)]
    for i in range(12):
        parts.append(box((0.006, 1.94, 0.003), (-0.88 + i * 0.16, 0, 0.231), solid("#2c1a10", 0.8), 0.0))
    curtain = velvet("#7a1a24")
    for i in range(20):
        x = -0.9 + i * 0.095
        parts.append(cylinder(0.055, 0.23, 1.5, curtain, (x, 0.9 + (0.02 if i % 2 else -0.02)), bevel=0.0, vertices=16))
    parts.append(box((1.98, 0.14, 0.14), (0, 0.9, 1.54), gold(), 0.012))
    for x in (-0.76, 0.76):
        parts.append(box((0.3, 0.3, 0.56), (x, 0.62, 0.51), solid("#17171c", 0.35), 0.012))
        for z, r in ((0.62, 0.1), (0.4, 0.075)):
            parts.append(disc(r, x, 0.466, z, cast_iron("#2d2e33"), 0.012))
    chrome = chrome_a()
    parts += [lathe([(0.0, 0.23), (0.12, 0.23), (0.12, 0.245), (0.0, 0.25)], cast_iron("#25262b"), (0.0, 0.1)),
              tube((0, 0.1, 0.24), (0, 0.1, 0.84), 0.01, chrome), tube((0, 0.1, 0.84), (0, 0.02, 0.9), 0.008, chrome), sphere(0.034, (0, 0.02, 0.92), cast_iron("#3a3a42"), (1, 1, 1.2))]
    return parts


def bookshelf():
    """Estante de biblioteca: nogueira, moldura no alto, livros de tons sóbrios e alguns objetos."""
    dark = wood(WALNUT, 0.45)
    w, d, h = 1.86, 0.44, 1.3
    parts = [box((w, 0.03, h), (0, d / 2 - 0.015, h / 2), wood("#3a2214", 0.2), 0.004), box((w + 0.04, d + 0.04, 0.09), (0, 0, 0.045), dark, 0.008),
             box((w + 0.08, d + 0.08, 0.05), (0, 0, h + 0.025), dark, 0.012), box((w + 0.03, d + 0.03, 0.03), (0, 0, h - 0.01), dark, 0.006)]
    for x in (-w / 2, -w / 6, w / 6, w / 2):
        parts.append(box((0.045, d, h), (x, 0, h / 2), dark, 0.006))
    colors = ("#7a1a24", "#23457f", "#c79a3c", "#2f5a3a", "#5a3a70", "#a55a2a", "#e0d4bc", "#2c2c34")
    rnd = random.Random(12)
    for z in (0.09, 0.5, 0.91):
        parts.append(box((w, d, 0.035), (0, 0, z), dark, 0.004))
        for bay in range(3):
            x = -w / 2 + 0.05 + bay * w / 3
            end = x + w / 3 - 0.08
            if (bay + int(z * 10)) % 4 == 3:   # uma prateleira com objeto em vez de livros
                parts.append(lathe([(0.0, z + 0.02), (0.05, z + 0.02), (0.09, z + 0.14), (0.05, z + 0.26), (0.03, z + 0.3), (0.0, z + 0.3)], glaze("#2f6f7f"), (x + w / 6 - 0.04, 0.02)))
                continue
            while x < end:
                bw = rnd.uniform(0.032, 0.06)
                bh = rnd.uniform(0.22, 0.33)
                book = box((bw, 0.25, bh), (x + bw / 2, 0.03, z + 0.018 + bh / 2), solid(colors[rnd.randrange(8)], 0.55), 0.003)
                parts.append(book)
                x += bw + 0.004
    return parts


def critic_statue():
    """O prêmio do crítico: pedestal de mármore e o toque de chef dourado, plissado."""
    metal = gold()
    parts = [box((0.56, 0.56, 0.1), (0, 0, 0.05), veined_marble("#ece6dc"), 0.01), box((0.44, 0.44, 0.5), (0, 0, 0.35), veined_marble("#f1eee8"), 0.008),
             box((0.54, 0.54, 0.06), (0, 0, 0.63), veined_marble("#ece6dc"), 0.01), box((0.2, 0.01, 0.08), (0, -0.226, 0.38), metal, 0.003)]
    parts.append(lathe([(0.0, 0.66), (0.19, 0.66), (0.2, 0.7), (0.19, 0.82), (0.19, 0.84), (0.2, 0.84), (0.0, 0.84)], metal))
    for i in range(10):
        a = 2 * math.pi * i / 10
        parts.append(sphere(0.095, (math.cos(a) * 0.15, math.sin(a) * 0.15, 0.94), metal, (1, 1, 1.25)))
    parts.append(sphere(0.2, (0, 0, 1.0), metal, (1, 1, 0.5)))
    return parts


def _cupcake(x, y, z, frosting):
    case = solid("#b08650", 0.65)
    return [lathe([(0.0, z), (0.032, z), (0.046, z + 0.05), (0.0, z + 0.05)], case, (x, y)),
            lathe([(0.052, z + 0.048), (0.045, z + 0.075), (0.028, z + 0.095), (0.016, z + 0.115), (0.004, z + 0.13), (0.0, z + 0.13)], solid(frosting, 0.5), (x, y)),
            sphere(0.011, (x, y, z + 0.13), solid("#c8283a", 0.3))]


def cupcake_tree():
    metal = gold()
    parts = [tube((0, 0, 0.0), (0, 0, 1.0), 0.014, metal), lathe([(0.0, 0.0), (0.2, 0.0), (0.2, 0.02), (0.04, 0.05), (0.0, 0.05)], metal), sphere(0.03, (0, 0, 1.0), metal)]
    frostings = ("#e7a6bd", "#8fbfdd", "#f8efd5", "#a6cf8a", "#6e4426")
    for z, r, ring in ((0.1, 0.32, 0.24), (0.42, 0.24, 0.16), (0.72, 0.16, 0.09)):
        parts.append(lathe([(0.0, z - 0.012), (r - 0.02, z - 0.012), (r, z), (r, z + 0.012), (0.0, z + 0.012)], solid("#f4efe4", 0.25, 0.0, 0.6), vertices=64))
        count = int(ring * 45)
        for i in range(count):
            a = 2 * math.pi * i / count
            parts += _cupcake(math.cos(a) * ring, math.sin(a) * ring, z + 0.012, frostings[i % 5])
    return parts


def chocolate_fountain():
    steel = brushed_steel("#d7dadb")
    choc = solid("#3f1f10", 0.12, 0.0, 0.9)
    parts = [lathe([(0.0, 0.0), (0.3, 0.0), (0.3, 0.02), (0.26, 0.28), (0.3, 0.3), (0.0, 0.3)], steel)]
    parts.append(lathe([(0.0, 0.3), (0.28, 0.3), (0.28, 0.32), (0.25, 0.33), (0.0, 0.33)], choc))
    for z, r in ((0.5, 0.2), (0.68, 0.14), (0.84, 0.085)):
        parts.append(lathe([(0.03, z - 0.05), (r, z), (r + 0.006, z + 0.016), (0.0, z + 0.016)], steel, vertices=64))
        parts.append(cylinder(r - 0.004, z + 0.012, z + 0.022, choc, vertices=64))
        for i in range(14):
            a = 2 * math.pi * i / 14
            parts.append(tube((math.cos(a) * r, math.sin(a) * r, z + 0.012), (math.cos(a) * (r + 0.012), math.sin(a) * (r + 0.012), z - 0.16), 0.011, choc))
    parts.append(tube((0, 0, 0.3), (0, 0, 0.92), 0.026, steel))
    parts.append(sphere(0.04, (0, 0, 0.93), steel))
    for i in range(10):
        a = i * 2 * math.pi / 10
        parts.append(sphere(0.026, (math.cos(a) * 0.3, math.sin(a) * 0.3, 0.325), solid("#c8283a", 0.35), (1, 1, 1.2)))
    return parts


def giant_pumpkin():
    orange = solid("#d9701f", 0.42, 0.0, 0.25)
    parts = [ribbed_ball(0.44, (0, 0, 0.38), orange, 12, 0.12, 0.86)]
    stem = solid("#5a6a2c", 0.7)
    parts.append(lathe([(0.075, 0.74), (0.04, 0.82), (0.035, 0.9), (0.055, 0.93), (0.0, 0.94)], stem))
    glow = emission("#ffb13d", 5.0)
    y = -0.415
    for x in (-0.15, 0.15):
        eye = cone(0.065, 0.46, 0.57, glow, (x, y), vertices=3)
        eye.rotation_euler = (math.radians(90), 0, 0)
        eye.location = (x, y, 0.49)
        parts.append(eye)
    parts.append(sphere(0.2, (0, y + 0.012, 0.25), glow, (1.2, 0.08, 0.32)))
    for x in (-0.08, 0.08):
        parts.append(box((0.05, 0.02, 0.05), (x, y - 0.01, 0.3), orange, 0.0))
    for side in (-1, 1):
        parts.append(leaf((side * 0.28, -0.26, 0.02), (side, -0.7, 0.04), 0.3, 0.1, foliage("#3f7a2a")))
    return parts


def witch_pumpkin(radius, center):
    return [ribbed_ball(radius, center, solid("#d9701f", 0.42, 0.0, 0.25), 10, 0.12, 0.86),
            cylinder(radius * 0.12, center[2] + radius * 0.8, center[2] + radius * 1.1, solid("#5a6a2c", 0.7), center[:2])]


def hay_bale():
    twine = solid("#6e4a24", 0.85)
    parts = [box((0.86, 0.6, 0.42), (0, 0, 0.21), straw(), 0.05), box((0.62, 0.44, 0.32), (0.08, 0.02, 0.58), straw(), 0.05)]
    for x in (-0.24, 0.24):
        parts.append(box((0.016, 0.62, 0.44), (x, 0, 0.21), twine, 0.004))
    for x in (-0.08, 0.24):
        parts.append(box((0.016, 0.46, 0.34), (x, 0.02, 0.58), twine, 0.004))
    rnd = random.Random(3)
    for _ in range(26):
        x, y = rnd.uniform(-0.4, 0.42), rnd.uniform(-0.3, 0.3)
        z = rnd.choice((0.42, 0.74))
        a = rnd.uniform(0, 6.28)
        parts.append(tube((x * (0.7 if z > 0.5 else 1), y, z), (x + math.cos(a) * 0.1, y + math.sin(a) * 0.1, z + 0.03), 0.003, solid("#d9b65a", 0.8)))
    return parts


def wagon_wheel():
    """Roda de carroça encostada no toco, virada para a câmera."""
    spoke = wood("#8c5526", 0.15)
    rim = cast_iron("#2d2e33")
    z = 0.52
    radius = 0.46
    rot = (math.radians(90), 0, math.radians(45))
    hub = Vector((0.03, -0.03, z))
    right = Vector((0.7071, 0.7071, 0.0))
    parts = [torus(radius, 0.022, hub, rim, rot), torus(radius - 0.04, 0.03, hub, spoke, rot)]
    for i in range(12):
        a = 2 * math.pi * i / 12
        end = hub + (right * math.cos(a) + Vector((0, 0, 1)) * math.sin(a)) * (radius - 0.05)
        parts.append(taper(tuple(hub), tuple(end), 0.024, 0.014, spoke))
    bpy.ops.mesh.primitive_cylinder_add(radius=0.075, depth=0.14, location=hub, rotation=rot, vertices=24)
    parts.append(M._finish(bpy.context.active_object, spoke, 0.012))
    bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=0.17, location=hub, rotation=rot, vertices=24)
    parts.append(M._finish(bpy.context.active_object, rim, 0.006))
    parts.append(lathe([(0.0, 0.0), (0.2, 0.0), (0.18, 0.14), (0.0, 0.14)], wood("#5d432a", 0.05), (-0.14, 0.14)))
    return parts


def wine_barrel():
    iron = cast_iron("#34353a")
    r = 0.33
    h = 0.7
    parts = [lathe([(0.0, 0.0), (r * 0.82, 0.0), (r * 0.92, h * 0.18), (r, h * 0.5), (r * 0.92, h * 0.82), (r * 0.82, h), (0.0, h)], staves("#7a4a26"), vertices=64)]
    for t, rad in ((0.08, 0.86), (0.28, 0.975), (0.72, 0.975), (0.92, 0.86)):
        parts.append(torus(r * rad, 0.012, (0, 0, h * t), iron))
    parts.append(lathe([(0.0, h), (r * 0.78, h), (r * 0.78, h + 0.008), (0.0, h + 0.008)], wood("#6e4324", 0.1)))
    bottle = solid("#1f3f2a", 0.08, 0.0, 1.0)
    z = h + 0.008
    parts.append(lathe([(0.0, z), (0.05, z), (0.052, z + 0.02), (0.052, z + 0.17), (0.018, z + 0.24), (0.016, z + 0.32), (0.0, z + 0.32)], bottle, (0.08, 0.06)))
    parts.append(box((0.05, 0.002, 0.07), (0.08, 0.008, z + 0.09), solid("#efe6d0", 0.5), 0.0))
    wine = solid("#5a1420", 0.08, 0.0, 0.8)
    parts.append(lathe([(0.0, z), (0.04, z), (0.042, z + 0.008), (0.008, z + 0.015), (0.008, z + 0.09), (0.045, z + 0.13), (0.05, z + 0.2), (0.046, z + 0.2), (0.038, z + 0.135), (0.0, z + 0.11)], glass("#ffffff", 0.3), (-0.12, -0.08)))
    parts.append(lathe([(0.0, z + 0.105), (0.04, z + 0.125), (0.044, z + 0.15), (0.0, z + 0.15)], wine, (-0.12, -0.08)))
    return parts


def eiffel():
    """A torre em ferro escuro: quatro pés curvos, arcos e treliça."""
    iron = cast_iron("#3d3a33")
    parts = [box((0.6, 0.6, 0.08), (0, 0, 0.04), veined_marble("#ece6dc"), 0.01), box((0.5, 0.5, 0.05), (0, 0, 0.1), veined_marble("#f1eee8"), 0.008)]

    def half(z):
        return 0.21 * (1 - (z - 0.12) / 1.34) ** 2.1 + 0.012
    levels = [0.12, 0.26, 0.42, 0.6, 0.8, 1.02, 1.24, 1.46]
    for sx in (-1, 1):
        for sy in (-1, 1):
            for a, b in zip(levels, levels[1:]):
                parts.append(tube((sx * half(a), sy * half(a), a), (sx * half(b), sy * half(b), b), 0.011 if a < 0.6 else 0.007, iron))
    for a, b in zip(levels[:6], levels[1:7]):   # treliça em X nas faces
        ha, hb = half(a), half(b)
        for sign in (-1, 1):
            parts.append(tube((-ha, sign * ha, a), (hb, sign * hb, b), 0.003, iron))
            parts.append(tube((ha, sign * ha, a), (-hb, sign * hb, b), 0.003, iron))
            parts.append(tube((sign * ha, -ha, a), (sign * hb, hb, b), 0.003, iron))
            parts.append(tube((sign * ha, ha, a), (sign * hb, -hb, b), 0.003, iron))
    for z, extra in ((0.42, 0.03), (0.8, 0.02), (1.24, 0.012)):
        side = 2 * half(z) + extra * 2
        parts.append(box((side, side, 0.018), (0, 0, z), iron, 0.003))
    for rot in (0, 90):
        bpy.ops.mesh.primitive_torus_add(major_radius=half(0.3) * 0.86, minor_radius=0.006, location=(0, 0, 0.26), rotation=(math.radians(90), 0, math.radians(rot)), major_segments=32, minor_segments=8)
        parts.append(M._finish(bpy.context.active_object, iron))
    parts.append(tube((0, 0, 1.44), (0, 0, 1.62), 0.006, iron))
    parts.append(sphere(0.012, (0, 0, 1.63), emission("#ffd27a", 12.0)))
    return parts


def parrot():
    frame = wood("#8c5526", 0.25)
    parts = [lathe([(0.0, 0.0), (0.17, 0.0), (0.17, 0.03), (0.05, 0.06), (0.024, 0.11), (0.0, 0.11)], frame), tube((0, 0, 0.1), (0, 0, 1.0), 0.018, frame),
             tube((-0.22, 0, 1.0), (0.22, 0, 1.0), 0.016, frame)]
    for x in (-0.22, 0.22):
        parts.append(cylinder(0.05, 0.96, 1.02, brushed_steel("#d7dadb"), (x, 0.0)))
    green = solid("#2d8a48", 0.4, 0.0, 0.3)
    parts.append(sphere(0.085, (0.0, 0.0, 1.14), green, (0.86, 0.84, 1.4)))
    parts.append(sphere(0.065, (0.0, -0.022, 1.28), solid("#c8283a", 0.4, 0.0, 0.3)))
    parts.append(sphere(0.032, (0.0, -0.075, 1.255), solid("#e7c980", 0.3), (0.8, 1.1, 1.2)))
    parts.append(sphere(0.022, (0.0, -0.086, 1.235), solid("#2c2c30", 0.3), (0.8, 1.0, 1.0)))
    for side in (-1, 1):
        parts.append(sphere(0.012, (side * 0.045, -0.06, 1.3), solid("#f4efe4", 0.4)))
        parts.append(sphere(0.006, (side * 0.05, -0.066, 1.3), solid("#101014", 0.2)))
        parts.append(leaf((side * 0.07, 0.0, 1.22), (side * 0.1, 0.25, -1), 0.22, 0.05, solid("#23479a", 0.4)))
        parts.append(sphere(0.022, (side * 0.03, -0.03, 1.02), solid("#3a3a40", 0.5), (1, 1.3, 0.5)))
    for i, color in enumerate(("#23479a", "#c8283a", "#e7b632")):
        parts.append(leaf((0.0, 0.05, 1.08), (-0.14 + i * 0.14, 0.35, -1), 0.3, 0.028, solid(color, 0.4)))
    return parts


def lava_lamp():
    chrome = chrome_a()
    parts = [lathe([(0.0, 0.0), (0.16, 0.0), (0.16, 0.02), (0.1, 0.2), (0.09, 0.3), (0.0, 0.3)], chrome)]
    parts.append(lathe([(0.0, 0.3), (0.09, 0.3), (0.115, 0.48), (0.08, 0.86), (0.05, 0.9), (0.0, 0.9)], emission("#f58a24", 0.75)))
    for z, r in ((0.4, 0.07), (0.56, 0.05), (0.7, 0.04), (0.81, 0.024)):
        parts.append(sphere(r, (0.05, -0.05, z), emission("#e8331e", 1.8), (1, 1, 1.3)))
    parts.append(lathe([(0.0, 0.3), (0.095, 0.3), (0.12, 0.48), (0.085, 0.86), (0.055, 0.9), (0.0, 0.905)], glass("#ffe8c0", 0.25)))
    parts.append(lathe([(0.055, 0.9), (0.04, 1.02), (0.02, 1.05), (0.0, 1.05)], chrome))
    return parts


def trophy(metal_color):
    metal = solid(metal_color, 0.26, 0.8, 0.3)
    base = solid("#17171c", 0.2, 0.0, 0.9)
    parts = [box((0.46, 0.46, 0.08), (0, 0, 0.04), veined_marble("#ece6dc"), 0.008), box((0.36, 0.36, 0.28), (0, 0, 0.22), base, 0.012), box((0.2, 0.008, 0.08), (0, -0.183, 0.22), metal, 0.002)]
    parts.append(lathe([(0.0, 0.36), (0.13, 0.36), (0.13, 0.38), (0.05, 0.42), (0.024, 0.46), (0.024, 0.56), (0.05, 0.58), (0.1, 0.62), (0.17, 0.82), (0.19, 0.96), (0.19, 0.98), (0.17, 0.98), (0.15, 0.84), (0.0, 0.66)], metal))
    rot = (math.radians(90), 0, math.radians(45))
    offset = Vector((0.7071, 0.7071, 0.0))
    for side in (-1, 1):
        parts.append(torus(0.085, 0.015, Vector((0, 0, 0.84)) + offset * side * 0.2, metal, rot))
    return parts


def trophy_bronze():
    return trophy("#a8703c")


def trophy_silver():
    return trophy("#c6ccd2")


def trophy_gold():
    return trophy("#d7a938")


# --- Máquinas -------------------------------------------------------------------------------------------------

def machine_cabinet(wood_color):
    """O móvel da máquina: rodapé, portas almofadadas e o tampo de pedra."""
    w = 0.92
    wood_mat = wood(wood_color, 0.45)
    dark = wood(M._shade(wood_color, 0.3), 0.2)
    parts = [box((w, w, CABINET_H - 0.05), (0, 0, (CABINET_H - 0.05) / 2 + 0.05), wood_mat, 0.008), box((w + 0.01, w + 0.01, 0.06), (0, 0, 0.03), dark, 0.005),
             box((w + 0.04, w + 0.04, 0.05), (0, 0, CABINET_H), stone_top(), 0.014)]
    for x in (-0.22, 0.22):
        parts.append(box((0.4, 0.02, CABINET_H - 0.14), (x, -w / 2 - 0.006, CABINET_H / 2 + 0.01), dark, 0.004))
        parts.append(box((0.34, 0.03, CABINET_H - 0.2), (x, -w / 2 - 0.012, CABINET_H / 2 + 0.01), wood_mat, 0.01))
        parts.append(sphere(0.012, (x * 0.2, -w / 2 - 0.035, CABINET_H / 2 + 0.03), gold()))
    return parts


CAB_TOP = CABINET_H + 0.025


def _cup(x, y, z, color="#f4efe4"):
    return lathe([(0.0, z), (0.03, z), (0.042, z + 0.06), (0.04, z + 0.06), (0.028, z + 0.008), (0.0, z + 0.008)], glaze(color), (x, y))


def machine_coffee():
    """Máquina de espresso de bar: corpo de aço curvo, cabeças de metal, manômetro, vaporizador e xícaras no alto."""
    steel = brushed_steel()
    red = enamel("#a8232f")
    parts = machine_cabinet("#5d3820")
    z = CAB_TOP
    profile = [(0.26, z), (-0.2, z), (-0.2, z + 0.1), (-0.14, z + 0.13), (-0.14, z + 0.3), (-0.26, z + 0.38), (-0.26, z + 0.46), (-0.2, z + 0.52), (0.26, z + 0.52)]
    parts.append(prism(profile, 0.78, steel, 0.02))
    parts.append(prism([(-0.27, z + 0.39), (-0.255, z + 0.39), (-0.255, z + 0.45), (-0.27, z + 0.45)], 0.7, red, 0.004))
    parts.append(box((0.8, 0.54, 0.02), (0.0, 0.02, z + 0.53), brushed_steel("#d7dadb"), 0.005))
    parts.append(box((0.74, 0.3, 0.05), (0, -0.26, z + 0.03), steel, 0.008))
    parts.append(box((0.68, 0.24, 0.008), (0, -0.26, z + 0.058), solid("#17171c", 0.35), 0.0))
    for x in (-0.2, 0.2):
        parts.append(cylinder(0.05, z + 0.24, z + 0.29, brushed_steel("#d7dadb"), (x, -0.2)))
        parts.append(cylinder(0.04, z + 0.2, z + 0.24, solid("#26262b", 0.4, 0.5), (x, -0.2)))
        parts.append(tube((x, -0.2, z + 0.22), (x, -0.36, z + 0.2), 0.012, solid("#17171c", 0.4)))
        parts.append(_cup(x, -0.22, z + 0.062))
    parts.append(disc(0.06, 0.0, -0.276, z + 0.42, gold(), 0.012))
    parts.append(disc(0.05, 0.0, -0.284, z + 0.42, solid("#f6efe0", 0.3), 0.004))
    parts.append(box((0.006, 0.004, 0.038), (0.008, -0.288, z + 0.43), solid("#c8283a", 0.4), 0.0))
    parts.append(tube((0.36, -0.14, z + 0.3), (0.42, -0.26, z + 0.1), 0.008, steel))
    for x in (-0.24, -0.08, 0.08, 0.24):
        for y in (-0.08, 0.1):
            parts.append(_cup(x, y, z + 0.54, ("#f4efe4", "#a8232f")[int(abs(x) * 100 + y * 100) % 2]))
    return parts


def machine_coffee_smart():
    """Máquina inteligente: bloco preto de vidro, tela de toque, faixa de luz e o reservatório de grãos."""
    parts = machine_cabinet("#3a2214")
    z = CAB_TOP
    black = solid("#14161f", 0.14, 0.0, 0.9)
    parts.append(box((0.58, 0.6, 0.72), (0, 0.04, z + 0.36), black, 0.03))
    parts.append(box((0.42, 0.008, 0.26), (0, -0.262, z + 0.52), emission("#1f8fd0", 1.6), 0.006))
    for i, c in enumerate(("#7ff0ff", "#7ff0ff", "#ffb24d")):
        parts.append(box((0.3 - i * 0.05, 0.004, 0.018), (0, -0.268, z + 0.58 - i * 0.05), emission(c, 4.0), 0.0))
    parts.append(box((0.44, 0.1, 0.24), (0, -0.21, z + 0.16), solid("#0a0a10", 0.2), 0.008))
    parts.append(cylinder(0.024, z + 0.26, z + 0.31, chrome_a(), (0.0, -0.21)))
    parts.append(_cup(0.0, -0.21, z + 0.04))
    parts.append(box((0.5, 0.2, 0.02), (0, -0.21, z + 0.022), brushed_steel("#a9acad"), 0.004))
    parts.append(box((0.6, 0.008, 0.02), (0, -0.262, z + 0.7), emission("#31d7ff", 5.0), 0.0))
    parts.append(lathe([(0.0, z + 0.72), (0.15, z + 0.72), (0.17, z + 0.9), (0.17, z + 0.92), (0.0, z + 0.92)], glass("#e4f5fb", 0.2), (0.0, 0.08)))
    parts.append(lathe([(0.0, z + 0.725), (0.14, z + 0.725), (0.155, z + 0.84), (0.0, z + 0.84)], solid("#3f2212", 0.6), (0.0, 0.08)))
    parts.append(lathe([(0.0, z + 0.92), (0.175, z + 0.92), (0.15, z + 0.95), (0.0, z + 0.95)], black, (0.0, 0.08)))
    return parts


def machine_juice():
    """Sucos: três cubas de vidro abauladas, com a tampa, a torneira e a pingadeira."""
    parts = machine_cabinet("#6e4324")
    z = CAB_TOP
    steel = brushed_steel()
    parts.append(box((0.84, 0.56, 0.14), (0, 0.04, z + 0.07), steel, 0.012))
    parts.append(box((0.8, 0.14, 0.02), (0, -0.28, z + 0.01), steel, 0.004))
    for x, color in ((-0.27, "#e8922a"), (0.0, "#e8d65a"), (0.27, "#d94f70")):
        base = z + 0.14
        parts.append(lathe([(0.0, base), (0.09, base), (0.125, base + 0.14), (0.115, base + 0.3), (0.09, base + 0.42), (0.0, base + 0.42)], glass("#f0fbff", 0.2), (x, 0.04)))
        parts.append(lathe([(0.0, base + 0.005), (0.085, base + 0.005), (0.112, base + 0.14), (0.103, base + 0.28), (0.0, base + 0.28)], solid(color, 0.12, 0.0, 0.9), (x, 0.04)))
        parts.append(lathe([(0.0, base + 0.42), (0.1, base + 0.42), (0.085, base + 0.46), (0.03, base + 0.48), (0.0, base + 0.5)], chrome_a(), (x, 0.04)))
        parts.append(tube((x, -0.1, z + 0.12), (x, -0.2, z + 0.11), 0.016, chrome_a()))
        parts.append(tube((x, -0.2, z + 0.13), (x, -0.2, z + 0.2), 0.009, solid("#17171c", 0.4)))
    return parts


def machine_frozen():
    """Frozen yogurt: corpo branco, duas cubas no alto, os bicos e a pilha de casquinhas."""
    parts = machine_cabinet("#7d532d")
    z = CAB_TOP
    white = solid("#f1ece2", 0.3, 0.0, 0.5)
    parts.append(prism([(0.26, z), (-0.14, z), (-0.14, z + 0.14), (-0.22, z + 0.18), (-0.22, z + 0.42), (-0.12, z + 0.56), (0.26, z + 0.56)], 0.66, white, 0.03))
    parts.append(box((0.6, 0.2, 0.05), (0, -0.24, z + 0.03), brushed_steel(), 0.008))
    for x, color in ((-0.15, "#e7a6bd"), (0.15, "#f6e9c8")):
        parts.append(cylinder(0.035, z + 0.2, z + 0.28, chrome_a(), (x, -0.23)))
        parts.append(lathe([(0.0, z + 0.2), (0.012, z + 0.14), (0.04, z + 0.2)], chrome_a(), (x, -0.23)))
        parts.append(tube((x, -0.23, z + 0.28), (x, -0.31, z + 0.38), 0.009, chrome_a()))
        parts.append(sphere(0.022, (x, -0.31, z + 0.39), solid("#17171c", 0.3)))
        base = z + 0.56
        parts.append(lathe([(0.0, base), (0.13, base), (0.14, base + 0.2), (0.0, base + 0.2)], glass("#f4fbff", 0.2), (x, 0.08)))
        parts.append(lathe([(0.0, base + 0.003), (0.122, base + 0.003), (0.13, base + 0.14), (0.0, base + 0.15)], solid(color, 0.35), (x, 0.08)))
        parts.append(lathe([(0.0, base + 0.2), (0.145, base + 0.2), (0.12, base + 0.23), (0.0, base + 0.24)], white, (x, 0.08)))
    parts.append(box((0.3, 0.012, 0.09), (0, -0.226, z + 0.36), solid("#2b3540", 0.2), 0.003))
    parts.append(lathe([(0.0, z + 0.03), (0.012, z + 0.03), (0.042, z + 0.13), (0.0, z + 0.13)], solid("#c79a5d", 0.7), (0.37, -0.24)))
    for i in range(3):
        parts.append(lathe([(0.042, z + 0.13 + i * 0.025), (0.046, z + 0.15 + i * 0.025), (0.0, z + 0.15 + i * 0.025)], solid("#c79a5d", 0.7), (0.37, -0.24)))
    parts.append(sphere(0.042, (0.37, -0.24, z + 0.23), solid("#e7a6bd", 0.5), (1, 1, 0.9)))
    return parts


# --- Trem, caldeirão e balcão de entregas ---------------------------------------------------------------------

def train_wheels(rim):
    """Rodas nos dois lados, de frente para o lado, com o braço de ferro ligando as de cada lado."""
    iron = cast_iron("#17171c")
    parts = []
    for side in (-1, 1):
        x = side * (K.W / 2 + 0.024)
        for y in (-0.3, 0.3):
            parts += spoked_wheel(x, y, 0.13, 0.13, iron, rim, 8, facing_y=False)
        parts.append(tube((x + side * 0.018, -0.3, 0.13), (x + side * 0.018, 0.3, 0.13), 0.011, rim))
    return parts


def train_locomotive():
    brass = gold()
    parts = range_stove(enamel("#8f1e2a"), brass, cast_iron("#17171c"), brass, panel=cast_iron("#2b2b30"), back=cast_iron("#232328"), base=cast_iron("#17171c"))
    x, y = 0.3, K.BACK_Y - 0.08
    iron = cast_iron("#17171c")
    parts.append(lathe([(0.075, K.H + 0.02), (0.075, K.H + 0.28), (0.13, K.H + 0.4), (0.13, K.H + 0.44), (0.0, K.H + 0.44)], iron, (x, y)))
    parts.append(torus(0.082, 0.012, (x, y, K.H + 0.14), brass))
    parts.append(sphere(0.09, (x + 0.02, y, K.H + 0.56), solid("#f0ece4", 0.95), (1.1, 1, 0.7)))
    parts.append(sphere(0.06, (x + 0.11, y, K.H + 0.66), solid("#f0ece4", 0.95), (1.1, 1, 0.7)))
    parts.append(lathe([(0.0, K.H + 0.32), (0.04, K.H + 0.32), (0.05, K.H + 0.25), (0.0, K.H + 0.25)], brass, (-0.28, K.BACK_Y)))
    # Limpa-trilhos na frente.
    parts.append(prism([(K.FRONT - 0.02, 0.12), (K.FRONT - 0.02, 0.0), (K.FRONT - 0.14, 0.0)], K.W - 0.1, iron, 0.004))
    return parts + train_wheels(brass)


def train_wagon():
    brass = gold()
    parts = range_stove(enamel("#22683a"), brass, cast_iron("#17171c"), brass, panel=enamel("#184e2b"), back=enamel("#184e2b"), base=cast_iron("#17171c"))
    for x in (-0.3, 0.0, 0.3):
        parts.append(box((0.22, 0.012, 0.18), (x, K.BACK_Y - 0.03, K.H + 0.15), emission("#ffe0a0", 1.3), 0.003))
        parts.append(box((0.24, 0.006, 0.02), (x, K.BACK_Y - 0.038, K.H + 0.15), brass, 0.0))
        parts.append(box((0.02, 0.006, 0.19), (x, K.BACK_Y - 0.038, K.H + 0.15), brass, 0.0))
    return parts + train_wheels(brass)


def train_dining():
    brass = gold()
    parts = range_stove(enamel("#23457f"), brass, brass, brass, panel=enamel("#1a3462"), back=enamel("#1a3462"), base=cast_iron("#17171c"))
    for x in (-0.28, 0.28):
        parts.append(box((0.3, 0.012, 0.2), (x, K.BACK_Y - 0.03, K.H + 0.15), emission("#ffe0a0", 1.3), 0.003))
        for side in (-1, 1):
            parts.append(box((0.08, 0.012, 0.21), (x + side * 0.11, K.BACK_Y - 0.036, K.H + 0.15), solid("#a8232f", 0.7), 0.003))
    parts.append(lathe([(0.0, K.H + 0.02), (0.04, K.H + 0.02), (0.012, K.H + 0.06), (0.012, K.H + 0.15), (0.0, K.H + 0.15)], brass, (0.0, K.BACK_Y - 0.1)))
    parts.append(lathe([(0.06, K.H + 0.15), (0.03, K.H + 0.22), (0.0, K.H + 0.23)], emission("#ffd27a", 2.0), (0.0, K.BACK_Y - 0.1)))
    return parts + train_wheels(brass)


def witch_cauldron():
    """Fogão da bruxa: ferro roxo, velas, abóbora, o morcego e o caldeirão de bolhas verdes no espelho."""
    iron = cast_iron("#1a1620")
    purple = enamel("#3f2169")
    parts = range_stove(purple, iron, solid("#d9701f", 0.3, 0.0, 0.5), iron, panel=iron, back=iron, chrome_legs=iron, door=enamel("#2e1850"))
    y = K.BACK_Y - 0.06
    top = K.H + 0.31
    parts += witch_pumpkin(0.13, (0.33, y, top + 0.1))
    parts.append(lathe([(0.0, top + 0.02), (0.11, top + 0.02), (0.17, top + 0.14), (0.14, top + 0.24), (0.15, top + 0.26), (0.0, top + 0.26)], iron, (-0.26, y)))
    parts.append(cylinder(0.13, top + 0.25, top + 0.262, emission("#58e04a", 2.4), (-0.26, y)))
    for dx, dz, r in ((-0.05, 0.3, 0.03), (0.04, 0.33, 0.022), (0.0, 0.4, 0.016)):
        parts.append(sphere(r, (-0.26 + dx, y, top + dz), emission("#7cf066", 3.0)))
    for x in (0.02, 0.1):
        parts.append(cylinder(0.018, K.H + 0.34, K.H + 0.46, solid("#efe6d0", 0.6), (x, y)))
        parts.append(sphere(0.012, (x, y, K.H + 0.48), emission("#ffb13d", 24.0), (1, 1, 1.7)))
    bat = solid("#101014", 0.5)
    parts.append(sphere(0.035, (0.06, y, K.H + 0.64), bat, (1, 0.7, 1.1)))
    for side in (-1, 1):
        parts.append(leaf((0.06 + side * 0.02, y, K.H + 0.65), (side, 0, 0.35), 0.14, 0.05, bat))
        parts.append(cone(0.012, K.H + 0.67, K.H + 0.7, bat, (0.06 + side * 0.018, y)))
    return parts


def delivery_counter():
    """Balcão de entregas: o balcão de madeira, caixas de papelão, sacola e a plaquinha de pedidos."""
    wood_mat = wood("#6e4324", 0.45)
    dark = wood("#3a2214", 0.2)
    parts = K.counter_core(wood_mat, dark, dark, stone_top()) + K.around(K.raised_panels(wood("#a8631f", 0.5), dark))
    h = M.COUNTER_HEIGHT + M.COUNTER_TOP
    kraft = solid("#b08650", 0.75)
    for x, y, s, z in ((0.3, 0.28, 0.24, 0.0), (0.3, 0.28, 0.17, 0.2), (0.05, 0.34, 0.15, 0.0)):
        parts.append(box((s, s, s * 0.82), (x, y, h + z + s * 0.41), kraft, 0.004))
        parts.append(box((s * 0.22, s + 0.004, s * 0.84), (x, y, h + z + s * 0.41), solid("#d9c49a", 0.6), 0.0))
    parts.append(box((0.14, 0.1, 0.2), (-0.3, 0.3, h + 0.1), solid("#c8283a", 0.7), 0.004))
    parts.append(tube((-0.36, 0.3, h + 0.2), (-0.3, 0.3, h + 0.26), 0.004, solid("#3a2214", 0.5)))
    parts.append(tube((-0.24, 0.3, h + 0.2), (-0.3, 0.3, h + 0.26), 0.004, solid("#3a2214", 0.5)))
    iron = cast_iron()
    parts.append(tube((-0.38, -0.34, h), (-0.38, -0.34, h + 0.28), 0.008, iron))
    parts.append(box((0.22, 0.012, 0.15), (-0.38, -0.34, h + 0.35), solid("#17171c", 0.6), 0.004))
    for z in (0.39, 0.35, 0.31):
        parts.append(box((0.15, 0.004, 0.012), (-0.38, -0.348, h + z), solid("#f4efe4", 0.6), 0.0))
    return parts


# --- Catálogo e fotos -------------------------------------------------------------------------------------------

ITEMS = {
    "plant_pot": plant_pot, "banana_tree": banana_tree, "bonsai": bonsai, "cactus": cactus, "olive_tree": olive_tree, "macrame_plant": macrame_plant,
    "succulents": succulents, "tree_blueberry": tree_blueberry, "tree_mango": tree_mango, "tree_strawberry": tree_strawberry, "flower_vase": flower_vase,
    "floor_lamp": floor_lamp, "edison_lamp": edison_lamp, "paper_lantern": paper_lantern, "paris_lamp": paris_lamp, "neon_diner": neon_diner, "station_clock": station_clock,
    "arcade": arcade, "claw_machine": claw_machine, "jukebox": jukebox, "boombox": boombox, "disco_ball": disco_ball, "dj_booth": dj_booth,
    "balloons": balloons, "party_cake": party_cake, "pinata": pinata, "popcorn_cart": popcorn_cart, "ring_toss": ring_toss, "stage": stage, "bookshelf": bookshelf,
    "critic_statue": critic_statue, "cupcake_tree": cupcake_tree, "chocolate_fountain": chocolate_fountain, "giant_pumpkin": giant_pumpkin, "hay_bale": hay_bale,
    "wagon_wheel": wagon_wheel, "wine_barrel": wine_barrel, "eiffel": eiffel, "parrot": parrot, "lava_lamp": lava_lamp,
    "trophy_bronze": trophy_bronze, "trophy_silver": trophy_silver, "trophy_gold": trophy_gold,
    "machine_coffee": machine_coffee, "machine_coffee_smart": machine_coffee_smart, "machine_juice": machine_juice, "machine_frozen": machine_frozen,
    "train_locomotive": train_locomotive, "train_wagon": train_wagon, "train_dining": train_dining, "witch_cauldron": witch_cauldron, "delivery_counter": delivery_counter,
}
FOOTPRINTS = {"bookshelf": (2, 1), "dj_booth": (2, 1), "stage": (2, 2)}
# Os redondos que têm um lado da frente: virados para a câmera. Os outros ficam no alinhamento do piso, como os móveis.
FACE_CAMERA = {"giant_pumpkin": 45.0, "parrot": 45.0}


def render(item_id, rotations, samples, anchors):
    footprint = FOOTPRINTS.get(item_id, (1, 1))
    for rotation in rotations:
        fx, fy = footprint if rotation % 2 == 0 else (footprint[1], footprint[0])
        width = int(128 * (fx + fy) + 180)
        cena3d.setup(samples, (width, 760), shadow_center=(fx / 2, -fy / 2), shadow_size=(fx + SHADOW_MARGIN, fy + SHADOW_MARGIN), rig="a")
        objects = [obj for obj in M._flatten(ITEMS[item_id]()) if obj is not None]
        anchor, center = M.assemble(objects, footprint, rotation)
        if FACE_CAMERA.get(item_id):
            parent = objects[0].parent
            parent.rotation_euler.z += math.radians(FACE_CAMERA[item_id])
            bpy.context.view_layer.update()
        aim_camera((center[0], center[1], 0.72))
        name = f"{item_id}_r{rotation}"
        anchors[name] = cena3d.shoot(name, anchor, WORK)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    samples = 24 if "rascunho" in args else 80
    wanted = [a for a in args if a in ITEMS] or list(ITEMS)
    with open(os.path.join(cena3d.SPRITES, "sprites.json"), encoding="utf-8") as source:
        manifest = json.load(source)
    anchors = {}
    for item_id in wanted:
        names = sorted(set(manifest["furniture"][item_id].values()))
        rotations = [int(name.rsplit("_r", 1)[1]) for name in names]
        render(item_id, rotations[:1] if "prova" in args else rotations, samples, anchors)
        cena3d.update_manifest(anchors)   # a cada item: se o próximo falhar, as fotos prontas não perdem a âncora
        print("PRONTO", item_id, flush=True)
    print("ENFEITES OK", len(anchors), flush=True)


if __name__ == "__main__":
    main()
