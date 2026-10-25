"""Enfeites, máquinas e fogões especiais em 3D (arte realista, DT-085): um modelo para cada um dos 53 móveis que não
são das famílias de moveis3d.py, a partir do desenho atual, fotografados no ângulo do jogo e gravados em art/sprites.

Uso (na pasta do projeto):
    C:/Blender/blender-5.2.3-windows-x64/blender.exe -b -P tools/render3d/enfeites3d.py -- [ids...] [rascunho]

Cada modelo é montado com o centro da pegada na origem e a frente virada para -Y (rotação 0), como em moveis3d.py.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cena3d  # noqa: E402
from cena3d import DESIGN_Z as PX, aim_camera  # noqa: E402
import moveis3d as M  # noqa: E402
from moveis3d import box, chrome, cylinder, emission, lacquer, solid, sphere, tube, wood  # noqa: E402

WORK = os.path.join(cena3d.ROOT, "tools", "render3d", "out_enfeites")
CABINET = 24 * PX            # armário de baixo das máquinas, como na arte 2D
MACHINE = 0.84


# --- Peças a mais -----------------------------------------------------------------------------------------------

def cone(radius, z0, z1, mat, center=(0.0, 0.0), top_radius=0.0, vertices=32):
    bpy.ops.mesh.primitive_cone_add(radius1=radius, radius2=top_radius, depth=z1 - z0, vertices=vertices,
                                    location=(center[0], center[1], (z0 + z1) / 2))
    return M._finish(bpy.context.active_object, mat, 0.002)


def torus(major, minor, center, mat, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, location=center, rotation=rotation,
                                     major_segments=48, minor_segments=12)
    return M._finish(bpy.context.active_object, mat)


def leaf(base, direction, length, width, mat):
    """Folha: um elipsoide fino da base para a direção pedida."""
    direction = Vector(direction).normalized()
    obj = sphere(1.0, Vector(base) + direction * length / 2, mat, (width, length / 2, 0.012))
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Y", "Z")
    return obj


def rosette(base, count, length, width, tilt, mat, droop=0.0, phase=0.0):
    """Folhas em roda, saindo da base, inclinadas [tilt] graus da vertical."""
    out = []
    for i in range(count):
        a = 2 * math.pi * i / count + phase
        t = math.radians(tilt)
        direction = (math.cos(a) * math.sin(t), math.sin(a) * math.sin(t), math.cos(t) - droop)
        out.append(leaf(base, direction, length, width, mat))
    return out


def foliage(color="#3f9a3a"):
    """Folhagem: verde com manchas de tom e relevo (copas de árvore e moitas)."""
    key = ("foliage", color)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Folhagem_" + color)
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 18.0
        noise.inputs["Detail"].default_value = 6.0
        links.new(M._coords(nodes, 1.0), noise.inputs["Vector"])
        links.new(M._ramp(nodes, links, noise.outputs["Fac"], M._shade(color, 0.35), M._tint(color, 0.25), (0.35, 0.7)),
                  bsdf.inputs["Base Color"])
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.8
        links.new(noise.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Roughness"].default_value = 0.7
        M._materials[key] = mat
    return M._materials[key]


def glass(color="#cfeefa", alpha=0.35):
    key = ("glass", color, alpha)
    if key not in M._materials:
        mat, _, _, bsdf = M._principled("Vidro_" + color)
        bsdf.inputs["Base Color"].default_value = cena3d.linear(color)
        bsdf.inputs["Roughness"].default_value = 0.03
        bsdf.inputs["Transmission Weight"].default_value = 1.0
        bsdf.inputs["Alpha"].default_value = alpha
        M._materials[key] = mat
    return M._materials[key]


def terracotta():
    return solid("#c9683a", 0.75)


def pot(radius, height, mat, rim=None):
    parts = [cone(radius * 0.78, 0.0, height, mat, top_radius=radius)]
    parts.append(torus(radius, radius * 0.08, (0, 0, height), rim or mat))
    parts.append(cylinder(radius * 0.92, height - 0.03, height - 0.005, solid("#4a3020", 0.95)))
    return parts


def lamp_glow(center, color="#ffd27a", radius=0.05, strength=18.0):
    return [sphere(radius, center, emission(color, strength)), sphere(radius * 3.2, center, glass(color, 0.08))]


def cabinet(color, wood_body=False):
    """Armário de base das máquinas, com as duas portinhas na frente (-Y)."""
    body = wood(color) if wood_body else lacquer(color)
    parts = [box((MACHINE, MACHINE, CABINET), (0, 0, CABINET / 2), body, 0.012)]
    for u in (-0.2, 0.2):
        parts.append(box((0.34, 0.02, CABINET * 0.72), (u, -MACHINE / 2 - 0.006, CABINET / 2), body, 0.01))
        parts.append(sphere(0.012, (u * 0.25, -MACHINE / 2 - 0.02, CABINET / 2), chrome()))
    return parts


def trunk(points, radius, mat):
    return [tube(a, b, radius * (1 - 0.15 * i), mat) for i, (a, b) in enumerate(zip(points, points[1:]))]


def fruit_tree(fruit_color, fruit_shape="round", fruit_size=0.035):
    parts = pot(0.2, 0.32, terracotta())
    parts += trunk([(0, 0, 0.3), (0.01, 0.0, 0.62)], 0.035, wood("#6b4a2a"))
    crown = foliage("#3c8f3a")
    for (x, y, z, r) in [(0, 0, 0.82, 0.3), (-0.17, 0.06, 0.74, 0.2), (0.17, -0.05, 0.76, 0.21), (0.05, 0.16, 0.9, 0.2),
                         (-0.05, -0.16, 0.92, 0.19)]:
        parts.append(sphere(r, (x, y, z), crown))
    for i in range(11):
        a = i * 2.4
        z = 0.72 + 0.22 * ((i * 37) % 10) / 10
        r = 0.27 + 0.03 * (i % 3)
        scale = (1.0, 1.0, 1.25) if fruit_shape == "drop" else (1.0, 1.0, 1.0)
        parts.append(sphere(fruit_size, (math.cos(a) * r, math.sin(a) * r - 0.04, z), solid(fruit_color, 0.35, 0.0, 0.4), scale))
    return parts


# --- Máquinas e fogões especiais ----------------------------------------------------------------------------------

def machine_coffee():
    parts = cabinet("#a86d40", wood_body=True)
    z = CABINET
    parts.append(box((0.62, 0.52, 0.5), (0, 0.02, z + 0.25), solid("#c9d0d8", 0.32, 1.0), 0.03))  # inox escovado
    parts.append(box((0.63, 0.53, 0.07), (0, 0.02, z + 0.445), lacquer("#d6283a"), 0.01))
    parts.append(box((0.58, 0.48, 0.012), (0, 0.02, z + 0.506), solid("#dfe4ea", 0.4, 0.6), 0.004))  # a chapa das xícaras
    for x in (-0.15, 0.15):
        parts.append(cylinder(0.025, z + 0.24, z + 0.3, solid("#2a2230", 0.4), (x, -0.25)))
        parts.append(cylinder(0.05, z, z + 0.08, solid("#ffffff", 0.2, 0.0, 0.6), (x, -0.27)))
    parts.append(torus(0.06, 0.012, (0, -0.245, z + 0.36), chrome(), (math.radians(90), 0, 0)))
    parts.append(box((0.09, 0.006, 0.09), (0, -0.246, z + 0.36), solid("#ffffff", 0.2), 0.04))  # o manômetro
    for (x, y) in ((-0.12, 0.08), (0.12, 0.08), (0.0, 0.2)):
        parts.append(cylinder(0.045, z + 0.5, z + 0.58, solid("#ffffff", 0.2, 0.0, 0.6), (x, y)))
    return parts


def machine_coffee_smart():
    parts = cabinet("#e9eef3")
    z = CABINET
    parts.append(box((0.62, 0.54, 0.58), (0, 0.02, z + 0.29), solid("#1d2433", 0.15, 0.0, 0.9), 0.03))
    parts.append(box((0.63, 0.55, 0.035), (0, 0.02, z + 0.56), emission("#31d7ff", 5.0), 0.004))
    parts.append(box((0.4, 0.008, 0.2), (0, -0.252, z + 0.4), emission("#1f8fd0", 2.5), 0.01))
    parts.append(box((0.24, 0.006, 0.02), (0.0, -0.257, z + 0.35), emission("#7ff0ff", 6.0), 0.002))
    parts.append(cylinder(0.025, z + 0.18, z + 0.24, chrome(), (0, -0.27)))
    parts.append(cylinder(0.05, z, z + 0.08, solid("#ffffff", 0.2, 0.0, 0.6), (0, -0.28)))
    parts.append(cylinder(0.07, z + 0.58, z + 0.64, solid("#cfd8e2", 0.2, 0.8)))
    return parts


def machine_juice():
    parts = cabinet("#2ec4b6")
    z = CABINET
    parts.append(box((0.74, 0.6, 0.14), (0, 0.04, z + 0.07), solid("#ffffff", 0.2, 0.0, 0.5), 0.02))
    for x, color in ((-0.22, "#ffa31a"), (0.0, "#f2ec7a"), (0.22, "#ff6f9a")):
        parts.append(cylinder(0.095, z + 0.14, z + 0.42, solid(color, 0.1, 0.0, 0.8), (x, 0.04)))
        parts.append(cylinder(0.1, z + 0.14, z + 0.56, glass("#e9f6ff", 0.25), (x, 0.04)))
        parts.append(cylinder(0.105, z + 0.56, z + 0.6, lacquer("#2ec4b6"), (x, 0.04)))
        parts.append(box((0.04, 0.03, 0.05), (x, -0.27, z + 0.08), solid("#3a3c46", 0.4), 0.006))
    return parts


def machine_frozen():
    parts = cabinet("#ff5c8a")
    z = CABINET
    parts.append(box((0.6, 0.5, 0.55), (0, 0.04, z + 0.275), solid("#f4f7fa", 0.25, 0.0, 0.6), 0.04))
    for x in (-0.13, 0.13):
        parts.append(cylinder(0.03, z + 0.2, z + 0.27, chrome(), (x, -0.23)))
        parts.append(sphere(0.035, (x, -0.245, z + 0.3), solid("#3a3c46", 0.3)))
    for x, color in ((-0.12, "#ff9ec4"), (0.12, "#fff3d6")):
        parts.append(cylinder(0.08, z + 0.55, z + 0.72, glass("#ffffff", 0.3), (x, 0.06)))
        parts.append(cylinder(0.07, z + 0.55, z + 0.66, solid(color, 0.4), (x, 0.06)))
    parts.append(cone(0.035, z, z + 0.08, solid("#d9a35a", 0.7), (0.0, -0.3), top_radius=0.05))
    parts.append(sphere(0.045, (0.0, -0.3, z + 0.1), solid("#ff9ec4", 0.5)))
    return parts


def stove_moon():
    parts = M.stove(enamel="#1d2a5a", top_color="#2a3a6e", panel=("#e8edf2", "#d9b44a", "#8a6a2e"), knob="#d9b44a",
                    door=("#2a3a6e", "#121a3a"), handle="#d9b44a")
    h = M.STOVE_HEIGHT
    parts.append(tube((0.3, 0.3, h), (0.3, 0.3, h + 0.28), 0.008, chrome("#d9b44a")))
    moon = solid("#ffd76a", 0.4)
    parts.append(sphere(0.09, (0.3, 0.3, h + 0.36), moon))
    parts.append(sphere(0.085, (0.34, 0.26, h + 0.39), lacquer("#1d2a5a")))
    for (x, y, z) in ((0.18, 0.36, h + 0.42), (0.38, 0.2, h + 0.5), (0.12, 0.2, h + 0.3)):
        parts.append(sphere(0.014, (x, y, z), emission("#fff6c2", 8.0)))
    return parts


def _wheels(color="#1d1d24", rim="#d9b44a"):
    out = []
    for x in (-0.28, 0.28):
        for y in (-0.47, 0.47):
            bpy.ops.mesh.primitive_cylinder_add(radius=0.09, depth=0.04, location=(x, y, 0.09), rotation=(math.radians(90), 0, 0))
            out.append(M._finish(bpy.context.active_object, solid(color, 0.4), 0.008))
            out.append(torus(0.06, 0.01, (x, y + (0.022 if y > 0 else -0.022), 0.09), chrome(rim), (math.radians(90), 0, 0)))
    return out


def _lifted(parts, dz):
    for obj in M._flatten(parts):
        obj.location.z += dz
    return parts


def train_locomotive():
    parts = _lifted(M.stove(enamel="#d6283a", top_color="#ffffff", knob="#1d1d24", door=("#a81e2c", "#6a121c"), handle="#d9b44a"), 0.06)
    h = M.STOVE_HEIGHT + 0.06
    parts.append(cylinder(0.06, h, h + 0.26, solid("#1d1d24", 0.35), (0.25, 0.25)))
    parts.append(cone(0.06, h + 0.26, h + 0.32, solid("#1d1d24", 0.35), (0.25, 0.25), top_radius=0.09))
    parts.append(sphere(0.07, (0.25, 0.25, h + 0.42), solid("#f4f4f4", 0.9), (1, 1, 0.7)))
    return parts + _wheels()


def train_wagon():
    parts = _lifted(M.stove(enamel="#2fae4e", top_color="#ffd23f", knob="#1d1d24", door=("#258a3e", "#165a28"), handle="#d9b44a"), 0.06)
    h = M.STOVE_HEIGHT + 0.06
    for (x, y, c) in ((-0.2, 0.22, "#8fd0ff"), (0.12, 0.25, "#cfeaff"), (0.28, -0.05, "#8fd0ff")):
        parts.append(box((0.12, 0.12, 0.12), (x, y, h + 0.07), lacquer(c), 0.01))
    return parts + _wheels()


def train_dining():
    parts = _lifted(M.stove(enamel="#2f5fbf", top_color="#ffffff", panel=("#fff3c4", "#e0c25a", "#9a7a2e"), knob="#e0c25a",
                            door=("#2a4fa0", "#1d3f86"), handle="#e0c25a"), 0.06)
    h = M.STOVE_HEIGHT + 0.06
    lid = box((0.8, 0.02, 0.26), (0.0, 0.36, h + 0.13), chrome(), 0.01)
    lid.rotation_euler = (math.radians(-18), 0, 0)
    parts.append(lid)
    return parts + _wheels()


def witch_cauldron():
    parts = M.stove(enamel="#4a2a7a", top_color="#6a3fa0", panel=("#ffd23f", "#e07a2e", "#8a4a1e"), knob="#ff8a2a",
                    door=("#3a1d5a", "#24113a"), handle="#ff8a2a")
    h = M.STOVE_HEIGHT
    parts += pumpkin(0.12, (0.25, 0.25, h + 0.01))
    bat = sphere(0.04, (-0.25, 0.3, h + 0.5), solid("#1d1d24", 0.5), (1.0, 0.6, 0.6))
    parts.append(bat)
    for side in (-1, 1):
        parts.append(leaf((-0.25 + side * 0.03, 0.3, h + 0.5), (side, 0, 0.35), 0.12, 0.05, solid("#1d1d24", 0.5)))
    return parts


# --- Plantas e árvores ----------------------------------------------------------------------------------------

def plant_pot():
    parts = pot(0.17, 0.3, lacquer("#ffcf3f"))
    green = foliage("#3fae4a")
    parts += rosette((0, 0, 0.3), 9, 0.42, 0.06, 32, green)
    parts += rosette((0, 0, 0.3), 6, 0.36, 0.055, 12, green, phase=0.5)
    return parts


def banana_tree():
    parts = pot(0.17, 0.3, lacquer("#ffcf3f"))
    parts.append(cylinder(0.035, 0.3, 0.8, solid("#7a9a3a", 0.6)))
    parts += rosette((0, 0, 0.78), 7, 0.5, 0.09, 58, foliage("#4fb840"), droop=0.35)
    for i in range(5):
        parts.append(sphere(0.022, (0.05, -0.04, 0.6 - i * 0.03), solid("#ffd23f", 0.5), (1, 1, 2.4)))
    return parts


def bonsai():
    parts = [box((0.4, 0.4, 0.18), (0, 0, 0.09), lacquer("#2f5fbf"), 0.02),
             box((0.36, 0.36, 0.01), (0, 0, 0.18), solid("#4a3020", 0.95), 0.0)]
    parts += trunk([(0, 0, 0.18), (0.05, 0.02, 0.32), (-0.04, -0.02, 0.45), (0.06, 0.0, 0.58)], 0.03, wood("#5a3a22"))
    for (x, y, z, r) in [(0.1, 0.05, 0.6, 0.12), (-0.12, 0.0, 0.47, 0.1), (0.14, -0.04, 0.38, 0.08), (0.0, 0.0, 0.66, 0.08)]:
        parts.append(sphere(r, (x, y, z), foliage("#4c9a3a"), (1.3, 1.3, 0.5)))
    return parts


def cactus():
    parts = pot(0.15, 0.24, terracotta(), rim=lacquer("#2f6fd9"))
    green = solid("#3f9a4a", 0.6)
    parts.append(cylinder(0.075, 0.24, 0.72, green, bevel=0.06))
    parts.append(sphere(0.075, (0, 0, 0.72), green))
    for side, z in ((-1, 0.42), (1, 0.5)):
        parts.append(tube((side * 0.06, 0, z), (side * 0.15, 0, z), 0.045, green))
        parts.append(cylinder(0.045, z, z + 0.16, green, (side * 0.15, 0)))
        parts.append(sphere(0.045, (side * 0.15, 0, z + 0.16), green))
    parts.append(sphere(0.03, (0, 0, 0.8), solid("#ff4d8d", 0.5)))
    return parts


def olive_tree():
    parts = pot(0.18, 0.3, terracotta())
    parts += trunk([(0, 0, 0.3), (0.04, 0.02, 0.55), (-0.02, 0.0, 0.78)], 0.03, wood("#7a6a52"))
    leaves = foliage("#7a9a5a")
    for (x, y, z, r) in [(0.0, 0.0, 0.88, 0.2), (-0.14, 0.04, 0.78, 0.14), (0.14, -0.04, 0.8, 0.15)]:
        parts.append(sphere(r, (x, y, z), leaves, (1.2, 1.2, 0.8)))
    for i in range(9):
        a = i * 2.2
        parts.append(sphere(0.022, (math.cos(a) * 0.2, math.sin(a) * 0.2 - 0.05, 0.76 + 0.04 * (i % 3)), solid("#3a3a2a", 0.3, 0.0, 0.6), (1, 1, 1.3)))
    return parts


def macrame_plant():
    rope = solid("#e8d8b8", 0.9)
    parts = [cylinder(0.16, 0.0, 0.04, wood("#a86d40"))]
    for a in range(3):
        ang = 2 * math.pi * a / 3
        parts.append(tube((math.cos(ang) * 0.13, math.sin(ang) * 0.13, 0.04), (0, 0, 1.25), 0.008, wood("#a86d40")))
    for a in range(4):
        ang = 2 * math.pi * a / 4
        parts.append(tube((math.cos(ang) * 0.11, math.sin(ang) * 0.11, 0.75), (0, 0, 1.18), 0.004, rope))
    parts += _lifted(pot(0.12, 0.16, terracotta()), 0.68)
    parts += rosette((0, 0, 0.84), 9, 0.28, 0.04, 70, foliage("#4fb840"), droop=0.6)
    return parts


def succulents():
    parts = [box((0.7, 0.4, 0.26), (0, 0, 0.13), wood("#e0a050"), 0.012), box((0.66, 0.36, 0.01), (0, 0, 0.26), solid("#5a4030", 0.95), 0)]
    for i, (x, c) in enumerate(((-0.22, "#7fc8a0"), (0.0, "#9ad08a"), (0.22, "#8ab8c8"))):
        parts += rosette((x, 0, 0.26), 8, 0.1, 0.035, 55 + i * 5, solid(c, 0.55), phase=i)
        parts += rosette((x, 0, 0.27), 5, 0.07, 0.03, 25, solid(M._tint(c, 0.2), 0.55))
    return parts


def tree_blueberry():
    return fruit_tree("#3a4aa0")


def tree_mango():
    return fruit_tree("#ffa31a", "drop", 0.045)


def tree_strawberry():
    return fruit_tree("#e0303a", "drop", 0.035)


def flower_vase():
    parts = [cylinder(0.12, 0.0, 0.42, solid("#f4f4f4", 0.3), bevel=0.01)]
    parts.append(cylinder(0.07, 0.42, 0.62, glass("#6a5ae0", 0.6), bevel=0.01))
    for i in range(9):
        a = i * 2.3
        top = (math.cos(a) * 0.08, math.sin(a) * 0.08, 0.86 + 0.05 * (i % 3))
        parts.append(tube((0, 0, 0.6), top, 0.004, solid("#2f8a3a")))
        parts.append(sphere(0.035, top, solid(("#ff4d6d", "#ffd23f", "#ffffff", "#ff8a3d", "#b06bff")[i % 5], 0.6)))
    return parts


# --- Luminárias e placas --------------------------------------------------------------------------------------

def floor_lamp():
    parts = [cylinder(0.13, 0.0, 0.03, solid("#1d1d24", 0.4), bevel=0.01), cylinder(0.014, 0.03, 1.15, solid("#2a2a33", 0.3, 0.7))]
    parts.append(cone(0.17, 1.12, 1.3, solid("#fff3c4", 0.6), top_radius=0.1))
    parts += lamp_glow((0, 0, 1.16), radius=0.04)
    return parts


def edison_lamp():
    iron = solid("#2a2a33", 0.3, 0.7)
    parts = [cylinder(0.13, 0.0, 0.03, iron, bevel=0.01), cylinder(0.014, 0.03, 1.35, iron)]
    parts.append(tube((0, 0, 1.35), (0.25, 0, 1.4), 0.012, iron))
    parts.append(tube((0.25, 0, 1.4), (0.25, 0, 1.22), 0.004, iron))
    parts.append(sphere(0.06, (0.25, 0, 1.15), glass("#ffe8b0", 0.4), (1, 1, 1.3)))
    parts.append(sphere(0.02, (0.25, 0, 1.15), emission("#ffb860", 25.0), (1, 1, 1.6)))
    return parts


def paper_lantern():
    iron = solid("#2a2a33", 0.3, 0.7)
    parts = [cylinder(0.12, 0.0, 0.03, iron, bevel=0.01), cylinder(0.014, 0.03, 1.4, iron), tube((0, 0, 1.4), (0.22, 0, 1.4), 0.012, iron)]
    parts.append(sphere(0.14, (0.22, 0, 1.12), emission("#ff4a3a", 2.5), (1, 1, 1.25)))
    parts.append(cylinder(0.06, 1.28, 1.31, solid("#1d1d24", 0.4), (0.22, 0)))
    parts.append(cylinder(0.06, 0.93, 0.96, solid("#1d1d24", 0.4), (0.22, 0)))
    return parts


def paris_lamp():
    iron = solid("#1f3a2e", 0.35, 0.6)
    parts = [cylinder(0.1, 0.0, 0.06, iron, bevel=0.01), cylinder(0.025, 0.06, 1.3, iron)]
    for side in (-1, 1):
        parts.append(tube((0, 0, 1.25), (side * 0.18, 0, 1.3), 0.012, iron))
        parts.append(cone(0.06, 1.3, 1.44, glass("#fff3c4", 0.3), (side * 0.18, 0), top_radius=0.04))
        parts.append(cone(0.07, 1.44, 1.5, iron, (side * 0.18, 0)))
        parts.append(sphere(0.025, (side * 0.18, 0, 1.36), emission("#ffd27a", 18.0)))
    return parts


def neon_diner():
    parts = [cylinder(0.11, 0.0, 0.03, solid("#2a2a33", 0.4, 0.5), bevel=0.01), cylinder(0.014, 0.03, 0.9, chrome())]
    parts.append(box((0.5, 0.06, 0.22), (0, 0, 1.0), solid("#1d1d2b", 0.3), 0.03))
    bpy.ops.object.text_add(location=(0, -0.035, 0.96), rotation=(math.radians(90), 0, 0))
    text = bpy.context.active_object
    text.data.body = "DINER"
    text.data.align_x = "CENTER"
    text.data.size = 0.13
    text.data.extrude = 0.004
    text.data.materials.append(emission("#ff4dd2", 8.0))
    parts.append(text)
    return parts


def station_clock():
    green = solid("#2f7a4a", 0.35, 0.4)
    parts = [cylinder(0.11, 0.0, 0.05, green, bevel=0.01), cylinder(0.025, 0.05, 1.05, green)]
    bpy.ops.mesh.primitive_cylinder_add(radius=0.13, depth=0.06, location=(0, 0, 1.18), rotation=(math.radians(90), 0, math.radians(45)))
    parts.append(M._finish(bpy.context.active_object, green, 0.01))
    for s in (-1, 1):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.11, depth=0.004, location=(s * 0.022, -s * 0.022, 1.18),
                                            rotation=(math.radians(90), 0, math.radians(45)))
        parts.append(M._finish(bpy.context.active_object, solid("#ffffff", 0.3), 0))
    parts.append(box((0.28, 0.02, 0.06), (0, 0, 0.62), solid("#ffffff", 0.3), 0.01))
    return parts


# --- Brinquedos, música e festa -------------------------------------------------------------------------------

def arcade():
    body = lacquer("#2a3fa0")
    parts = [box((0.62, 0.6, 1.25), (0, 0.05, 0.625), body, 0.02)]
    parts.append(box((0.5, 0.02, 0.36), (0, -0.26, 0.92), emission("#4fd0ff", 2.0), 0.01))
    parts.append(box((0.56, 0.24, 0.06), (0, -0.3, 0.62), lacquer("#ff4d8d"), 0.01))
    for x, c in ((-0.15, "#ffd23f"), (0.0, "#ff4d5e"), (0.12, "#31d7ff")):
        parts.append(sphere(0.022, (x, -0.33, 0.66), solid(c, 0.3)))
    parts.append(box((0.62, 0.62, 0.08), (0, 0.04, 1.28), emission("#ff4dd2", 2.0), 0.01))
    return parts


def claw_machine():
    parts = [box((0.66, 0.66, 0.42), (0, 0, 0.21), lacquer("#d6283a"), 0.015)]
    parts.append(box((0.64, 0.64, 0.5), (0, 0, 0.67), glass("#dff4ff", 0.2), 0.01))
    for i in range(8):
        a = i * 2.1
        parts.append(sphere(0.06, (math.cos(a) * 0.18, math.sin(a) * 0.18, 0.47), solid(("#ff9ec4", "#ffd23f", "#8fd0ff", "#9ae08a")[i % 4], 0.8)))
    parts.append(tube((0, 0, 0.92), (0, 0, 0.72), 0.006, chrome()))
    parts.append(box((0.68, 0.68, 0.14), (0, 0, 0.99), lacquer("#ffcf3f"), 0.02))
    return parts


def jukebox():
    body = lacquer("#ff3d7f")
    parts = [box((0.62, 0.46, 1.0), (0, 0.05, 0.5), body, 0.03)]
    bpy.ops.mesh.primitive_cylinder_add(radius=0.31, depth=0.46, location=(0, 0.05, 1.0), rotation=(math.radians(90), 0, 0))
    parts.append(M._finish(bpy.context.active_object, body, 0.02))
    parts.append(box((0.42, 0.02, 0.22), (0, -0.19, 0.78), glass("#cfeaff", 0.5), 0.01))
    for i, c in enumerate(("#ff4d5e", "#ffd23f", "#2fae4e", "#31d7ff", "#b06bff")):
        parts.append(box((0.05, 0.02, 0.3), (-0.16 + i * 0.08, -0.19, 0.38), emission(c, 3.0), 0.008))
    return parts


def boombox():
    parts = [box((0.6, 0.5, 0.36), (0, 0, 0.18), lacquer("#ffcf3f"), 0.02)]
    parts.append(box((0.62, 0.24, 0.32), (0, 0, 0.52), solid("#1d1d24", 0.35, 0.0, 0.5), 0.03))
    for x in (-0.18, 0.18):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.1, depth=0.02, location=(x, -0.12, 0.52), rotation=(math.radians(90), 0, 0))
        parts.append(M._finish(bpy.context.active_object, solid("#3a3c46", 0.5), 0.005))
    parts.append(box((0.16, 0.01, 0.07), (0, -0.125, 0.52), emission("#4fd0ff", 3.0), 0.004))
    parts.append(tube((-0.24, 0, 0.68), (-0.24, 0, 0.76), 0.012, chrome()))
    parts.append(tube((0.24, 0, 0.68), (0.24, 0, 0.76), 0.012, chrome()))
    parts.append(tube((-0.24, 0, 0.76), (0.24, 0, 0.76), 0.012, chrome()))
    return parts


def disco_ball():
    parts = [cylinder(0.12, 0.0, 0.03, solid("#1d1d24", 0.4), bevel=0.01), cylinder(0.012, 0.03, 1.3, chrome())]
    parts.append(tube((0, 0, 1.3), (0.15, 0, 1.3), 0.01, chrome()))
    parts.append(tube((0.15, 0, 1.3), (0.15, 0, 1.23), 0.004, chrome()))
    parts.append(sphere(0.13, (0.15, 0, 1.1), mirror_tiles()))
    return parts


def mirror_tiles():
    """Globo espelhado: quadradinhos de espelho com as juntas escuras."""
    key = ("mirror_tiles",)
    if key not in M._materials:
        mat, nodes, links, bsdf = M._principled("Espelhinhos")
        brick = nodes.new("ShaderNodeTexBrick")
        brick.inputs["Scale"].default_value = 30.0
        brick.inputs["Mortar Size"].default_value = 0.06
        brick.inputs["Color1"].default_value = cena3d.linear("#f4f7fa")
        brick.inputs["Color2"].default_value = cena3d.linear("#c9d3de")
        brick.inputs["Mortar"].default_value = cena3d.linear("#2a2a33")
        coords = nodes.new("ShaderNodeTexCoord")
        links.new(coords.outputs["UV"], brick.inputs["Vector"])
        links.new(brick.outputs["Color"], bsdf.inputs["Base Color"])
        links.new(brick.outputs["Fac"], bsdf.inputs["Roughness"])
        bsdf.inputs["Metallic"].default_value = 1.0
        M._materials[key] = mat
    return M._materials[key]


def dj_booth():
    parts = [box((1.8, 0.6, 0.62), (0, 0, 0.31), solid("#1d1d24", 0.3, 0.0, 0.6), 0.02)]
    for i, c in enumerate(("#b06bff", "#4fa0ff", "#31d7ff", "#2fae4e", "#ffd23f", "#ff8a2a", "#ff4d5e")):
        parts.append(box((0.2, 0.01, 0.4), (-0.66 + i * 0.22, -0.305, 0.31), emission(c, 2.5), 0.004))
    for x in (-0.5, 0.5):
        parts.append(cylinder(0.18, 0.62, 0.66, solid("#2a2a33", 0.3), (x, 0.0)))
        parts.append(cylinder(0.08, 0.66, 0.67, lacquer("#e0303a"), (x, 0.0)))
    parts.append(box((0.4, 0.36, 0.04), (0, 0, 0.64), solid("#3a3c46", 0.3), 0.006))
    return parts


def balloons():
    parts = [cylinder(0.05, 0.0, 0.06, lacquer("#ffcf3f"), bevel=0.01)]
    for (x, y, z, c) in ((0.0, 0.0, 1.25, "#ffd23f"), (-0.15, 0.05, 1.15, "#ff4d6d"), (0.15, -0.05, 1.12, "#31d7ff"),
                         (-0.05, -0.12, 1.02, "#b06bff"), (0.12, 0.12, 1.0, "#2fae4e")):
        parts.append(tube((0, 0, 0.06), (x, y, z - 0.12), 0.002, solid("#ffffff", 0.5)))
        parts.append(sphere(0.12, (x, y, z), solid(c, 0.15, 0.0, 0.8), (1, 1, 1.18)))
    return parts


def party_cake():
    parts = [cylinder(0.2, 0.0, 0.03, solid("#f4f4f4", 0.2, 0.0, 0.6)), cylinder(0.03, 0.03, 0.3, solid("#f4f4f4", 0.2, 0.0, 0.6)),
             cylinder(0.3, 0.3, 0.33, solid("#f4f4f4", 0.2, 0.0, 0.6), bevel=0.01)]
    parts.append(cylinder(0.24, 0.33, 0.5, lacquer("#ff9ec4"), bevel=0.02))
    parts.append(cylinder(0.17, 0.5, 0.64, lacquer("#8fd0ff"), bevel=0.02))
    for i in range(5):
        a = i * 2 * math.pi / 5
        x, y = math.cos(a) * 0.09, math.sin(a) * 0.09
        parts.append(cylinder(0.01, 0.64, 0.74, solid(("#ff4d6d", "#ffd23f", "#31d7ff", "#2fae4e", "#b06bff")[i], 0.4), (x, y)))
        parts.append(sphere(0.01, (x, y, 0.76), emission("#ffb13d", 20.0), (1, 1, 1.6)))
    return parts


def pinata():
    wood_mat = wood("#c98a52")
    parts = [box((0.3, 0.3, 0.03), (0, 0, 0.015), wood_mat, 0.005), cylinder(0.014, 0.03, 1.35, wood_mat)]
    parts.append(tube((0, 0, 1.35), (0.25, 0, 1.35), 0.012, wood_mat))
    parts.append(tube((0.25, 0, 1.35), (0.25, 0, 1.1), 0.003, solid("#e8d8b8", 0.9)))
    for i, c in enumerate(("#ff4d6d", "#ffd23f", "#2fae4e", "#31d7ff")):
        parts.append(sphere(0.11 - i * 0.004, (0.25, 0, 1.02 - i * 0.05), solid(c, 0.8), (1.25, 0.8, 0.45)))
    for i, c in enumerate(("#b06bff", "#ff8a2a", "#31d7ff")):
        parts.append(tube((0.18 + i * 0.07, 0, 0.86), (0.18 + i * 0.07, 0, 0.72), 0.008, solid(c, 0.8)))
    return parts


def popcorn_cart():
    parts = [box((0.56, 0.5, 0.5), (0, 0, 0.32), lacquer("#d6283a"), 0.02)]
    for x in (-0.22, 0.22):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.04, location=(x, -0.27, 0.08), rotation=(math.radians(90), 0, 0))
        parts.append(M._finish(bpy.context.active_object, solid("#1d1d24", 0.4), 0.006))
    parts.append(box((0.5, 0.44, 0.4), (0, 0, 0.77), glass("#f4fbff", 0.2), 0.01))
    for i in range(14):
        parts.append(sphere(0.035, ((i % 4 - 1.5) * 0.09, ((i // 4) % 3 - 1) * 0.1, 0.62 + 0.04 * (i // 4)), solid("#fff3c4", 0.8)))
    roof = box((0.62, 0.56, 0.06), (0, 0, 1.0), lacquer("#ffffff"), 0.01)
    parts.append(roof)
    for i in range(5):
        parts.append(box((0.62 / 5 / 2, 0.57, 0.062), (-0.25 + i * 0.124, 0, 1.0), lacquer("#d6283a"), 0.0))
    return parts


def ring_toss():
    parts = [box((0.84, 0.6, 0.5), (0, 0, 0.25), lacquer("#2f6fd9"), 0.012)]
    for i in range(4):
        parts.append(box((0.1, 0.61, 0.5), (-0.31 + i * 0.2, 0, 0.25), solid("#ffffff", 0.3), 0.0))
    for (x, y, c) in ((-0.2, 0.0, "#2f7a3a"), (0.05, 0.1, "#7a2fd0"), (0.25, -0.05, "#d6283a")):
        parts.append(cylinder(0.04, 0.5, 0.72, solid(c, 0.08, 0.0, 1.0), (x, y)))
        parts.append(cylinder(0.015, 0.72, 0.8, solid(c, 0.08, 0.0, 1.0), (x, y)))
    for (x, y, c) in ((-0.05, -0.15, "#ffd23f"), (0.15, 0.15, "#31d7ff")):
        parts.append(torus(0.07, 0.012, (x, y, 0.52), solid(c, 0.4)))
    return parts


def stage():
    parts = [box((1.9, 1.9, 0.16), (0, 0, 0.08), wood("#a8743e"), 0.01), box((1.94, 1.94, 0.03), (0, 0, 0.17), wood("#c98a52"), 0.006)]
    for (x, y) in ((-0.7, 0.7), (0.7, 0.7)):
        parts.append(box((0.24, 0.24, 0.42), (x, y, 0.4), solid("#1d1d24", 0.35), 0.015))
        bpy.ops.mesh.primitive_cylinder_add(radius=0.07, depth=0.01, location=(x, y - 0.122, 0.46), rotation=(math.radians(90), 0, 0))
        parts.append(M._finish(bpy.context.active_object, solid("#3a3c46", 0.5), 0))
    parts.append(tube((0, 0.2, 0.18), (0, 0.2, 0.75), 0.008, chrome()))
    parts.append(sphere(0.03, (0, 0.2, 0.78), solid("#2a2a33", 0.4, 0.6)))
    return parts


def bookshelf():
    """Estante aberta na frente (-Y): laterais, fundo, prateleiras e os livros coloridos."""
    white = solid("#f4f4f4", 0.35)
    w, d, h = 1.8, 0.4, 1.0
    parts = [box((w, 0.03, h), (0, d / 2, h / 2), solid("#e4e6ea", 0.5), 0.004)]
    for x in (-w / 2, w / 2):
        parts.append(box((0.04, d, h), (x, 0.0, h / 2), white, 0.006))
    colors = ("#e0303a", "#2f6fd9", "#ffd23f", "#2fae4e", "#b06bff", "#ff8a2a", "#31d7ff", "#ff4d8d")
    for row, z in enumerate((0.04, 0.36, 0.68, h - 0.02)):
        parts.append(box((w, d, 0.04), (0, 0.0, z - 0.02), white, 0.004))
        if z >= h - 0.05:
            break
        x = -w / 2 + 0.05
        i = row * 3
        while x < w / 2 - 0.1:
            bw = 0.05 + 0.025 * ((i * 7) % 3)
            bh = 0.2 + 0.05 * ((i * 5) % 3)
            parts.append(box((bw, 0.26, bh), (x + bw / 2, 0.04, z + bh / 2), solid(colors[i % len(colors)], 0.5), 0.004))
            x += bw + 0.008
            i += 1
    return parts


def delivery_counter():
    parts = M.counter(body="#f07a1a", top="#fff3e0", face="panels", rim="#c9d3de", veins=False)
    h = M.COUNTER_HEIGHT + M.COUNTER_TOP
    for (x, y, s, c) in ((-0.12, 0.1, 0.18, "#c98a52"), (0.06, 0.15, 0.14, "#d9a066"), (0.15, -0.1, 0.16, "#d6283a")):
        parts.append(box((s, s, s * 0.8), (x, y, h + s * 0.4), solid(c, 0.75), 0.006))
    parts.append(tube((0.3, 0.3, h), (0.3, 0.3, h + 0.35), 0.008, chrome()))
    parts.append(box((0.2, 0.02, 0.12), (0.3, 0.3, h + 0.4), solid("#ffffff", 0.3), 0.01))
    return parts


def critic_statue():
    parts = [box((0.42, 0.42, 0.5), (0, 0, 0.25), M.marble("#f2ead8"), 0.01)]
    gold = solid("#e8b830", 0.2, 1.0)
    parts.append(cylinder(0.13, 0.5, 0.66, gold, bevel=0.02))
    for (x, y) in ((0, 0), (-0.1, 0.04), (0.1, 0.04), (0.0, 0.12), (-0.05, -0.08), (0.06, -0.08)):
        parts.append(sphere(0.1, (x, y, 0.74), gold))
    parts.append(box((0.08, 0.01, 0.08), (-0.1, -0.212, 0.3), gold, 0.01))
    return parts


def cupcake_tree():
    stand = solid("#f4f4f4", 0.2, 0.0, 0.6)
    parts = [cylinder(0.012, 0.0, 0.85, stand)]
    for z, r in ((0.05, 0.26), (0.35, 0.2), (0.62, 0.14)):
        parts.append(cylinder(r, z, z + 0.02, stand))
        n = int(r * 30)
        for i in range(n):
            a = 2 * math.pi * i / n
            x, y = math.cos(a) * (r - 0.06), math.sin(a) * (r - 0.06)
            parts.append(cone(0.035, z + 0.02, z + 0.08, solid("#f4d6a0", 0.7), (x, y), top_radius=0.045))
            parts.append(sphere(0.045, (x, y, z + 0.1), solid(("#ff9ec4", "#8fd0ff", "#fff3c4", "#b0e090")[i % 4], 0.5), (1, 1, 0.8)))
    parts.append(sphere(0.03, (0, 0, 0.88), solid("#e0303a", 0.3)))
    return parts


def chocolate_fountain():
    parts = [cylinder(0.24, 0.0, 0.3, solid("#f4f4f4", 0.2, 0.0, 0.6), bevel=0.02)]
    choc = solid("#5a2e18", 0.15, 0.0, 0.8)
    for z, r in ((0.3, 0.2), (0.48, 0.14), (0.64, 0.09)):
        parts.append(cylinder(r, z, z + 0.04, choc, bevel=0.01))
    parts.append(cylinder(0.02, 0.3, 0.8, chrome()))
    parts.append(cylinder(0.05, 0.3, 0.75, choc))
    for i in range(4):
        a = i * math.pi / 2
        parts.append(sphere(0.025, (math.cos(a) * 0.22, math.sin(a) * 0.22, 0.38), solid("#e0303a", 0.3)))
    return parts


def giant_pumpkin():
    return pumpkin(0.4, (0, 0, 0.0), face=True)


def pumpkin(radius, base, face=False):
    orange = solid("#f07a1a", 0.45, 0.0, 0.3)
    parts = []
    for i in range(8):
        a = 2 * math.pi * i / 8
        parts.append(sphere(radius * 0.55, (base[0] + math.cos(a) * radius * 0.42, base[1] + math.sin(a) * radius * 0.42, base[2] + radius * 0.6),
                            orange, (1.0, 1.0, 1.05)))
    parts.append(sphere(radius * 0.7, (base[0], base[1], base[2] + radius * 0.62), orange))
    parts.append(cylinder(radius * 0.08, base[2] + radius * 1.1, base[2] + radius * 1.3, solid("#4a6a2a", 0.7), base[:2]))
    if face:
        glow = emission("#ffb13d", 6.0)
        for x in (-0.12, 0.12):
            parts.append(sphere(0.05, (base[0] + x, base[1] - radius * 0.98, base[2] + radius * 0.8), glow, (1.2, 0.3, 0.8)))
        parts.append(sphere(0.12, (base[0], base[1] - radius * 0.98, base[2] + radius * 0.42), glow, (1.4, 0.3, 0.4)))
        for side in (-1, 1):
            parts.append(leaf((base[0] + side * radius * 0.6, base[1] - radius * 0.3, base[2] + 0.02), (side, -0.6, 0.05), radius * 0.6,
                              radius * 0.25, foliage("#4a8a2a")))
    return parts


def hay_bale():
    hay = solid("#e0b84a", 0.9)
    parts = [box((0.8, 0.56, 0.44), (0, 0, 0.22), hay, 0.04)]
    for x in (-0.2, 0.2):
        parts.append(box((0.03, 0.58, 0.46), (x, 0, 0.22), solid("#8a5a2a", 0.8), 0.004))
    return parts


def wagon_wheel():
    wood_mat = wood("#a86d40")
    bpy.ops.mesh.primitive_torus_add(major_radius=0.42, minor_radius=0.03, location=(0, 0, 0.45), rotation=(math.radians(90), 0, math.radians(45)),
                                     major_segments=64, minor_segments=12)
    parts = [M._finish(bpy.context.active_object, wood_mat)]
    hub = (0, 0, 0.45)
    for i in range(10):
        a = 2 * math.pi * i / 10
        end = Vector((math.cos(a) * 0.42 * 0.707, math.cos(a) * 0.42 * 0.707, 0.45 + math.sin(a) * 0.42))  # de frente para a câmera
        parts.append(tube(hub, end, 0.014, wood_mat))
    parts.append(sphere(0.06, hub, solid("#3a3c46", 0.4, 0.6), (1, 1, 1)))
    return parts


def wine_barrel():
    wood_mat = wood("#8a5530")
    parts = [cylinder(0.3, 0.0, 0.62, wood_mat, bevel=0.03, vertices=24)]
    for z in (0.08, 0.31, 0.54):
        parts.append(cylinder(0.305, z - 0.02, z + 0.02, solid("#3a3c46", 0.4, 0.7)))
    parts.append(cylinder(0.04, 0.62, 0.86, solid("#2f6a3a", 0.05, 0.0, 1.0), (0.08, 0.06)))
    parts.append(cylinder(0.014, 0.86, 0.94, solid("#2f6a3a", 0.05, 0.0, 1.0), (0.08, 0.06)))
    parts.append(cone(0.035, 0.7, 0.76, glass("#ffffff", 0.3), (-0.1, -0.05), top_radius=0.045))
    parts.append(cylinder(0.006, 0.62, 0.7, glass("#ffffff", 0.3), (-0.1, -0.05)))
    parts.append(cylinder(0.034, 0.7, 0.73, solid("#7a1a2a", 0.1), (-0.1, -0.05)))
    return parts


def eiffel():
    iron = solid("#8a6a3a", 0.4, 0.6)
    parts = [box((0.36, 0.36, 0.08), (0, 0, 0.04), solid("#f4f4f4", 0.3), 0.01)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(tube((sx * 0.13, sy * 0.13, 0.08), (sx * 0.03, sy * 0.03, 0.75), 0.012, iron))
    for z, r in ((0.28, 0.09), (0.5, 0.05)):
        parts.append(box((r * 2.2, r * 2.2, 0.03), (0, 0, z), iron, 0.004))
    parts.append(tube((0, 0, 0.75), (0, 0, 1.05), 0.01, iron))
    return parts


def parrot():
    wood_mat = wood("#c98a52")
    parts = [cylinder(0.12, 0.0, 0.03, wood_mat, bevel=0.01), cylinder(0.014, 0.03, 1.0, wood_mat), tube((-0.15, 0, 1.0), (0.15, 0, 1.0), 0.014, wood_mat)]
    parts.append(sphere(0.07, (0.0, 0.0, 1.1), solid("#2fae4e", 0.5), (0.9, 0.8, 1.2)))
    parts.append(sphere(0.05, (0.0, -0.03, 1.2), solid("#e0303a", 0.5)))
    parts.append(cone(0.015, 1.18, 1.21, solid("#ffd23f", 0.4), (0.0, -0.08)))
    parts.append(leaf((0.0, 0.05, 1.06), (0, 0.4, -1), 0.18, 0.03, solid("#2f6fd9", 0.5)))
    return parts


def lava_lamp():
    parts = [cone(0.1, 0.0, 0.25, chrome(), top_radius=0.06)]
    parts.append(cone(0.07, 0.25, 0.75, glass("#ffd060", 0.6), top_radius=0.045))
    for z, r in ((0.35, 0.045), (0.52, 0.035), (0.64, 0.03)):
        parts.append(sphere(r, (0, 0, z), emission("#ff4a2a", 3.0), (1, 1, 1.3)))
    parts.append(cone(0.06, 0.26, 0.74, emission("#ffb040", 1.2), top_radius=0.04))  # o líquido aceso
    parts.append(cone(0.045, 0.75, 0.86, chrome(), top_radius=0.02))
    parts.append(sphere(0.24, (0, 0, 0.52), lava_halo(), (1.0, 1.0, 1.5)))   # o brilho em volta, como no desenho
    return parts


def lava_halo():
    key = ("lava_halo",)
    if key not in M._materials:
        mat, _, _, bsdf = M._principled("Halo_lava")
        bsdf.inputs["Base Color"].default_value = cena3d.linear("#ffb040")
        bsdf.inputs["Emission Color"].default_value = cena3d.linear("#ffb040")
        bsdf.inputs["Emission Strength"].default_value = 0.6
        bsdf.inputs["Alpha"].default_value = 0.16
        M._materials[key] = mat
    return M._materials[key]


# --- Troféus ----------------------------------------------------------------------------------------------------

def trophy(metal):
    parts = [box((0.36, 0.36, 0.3), (0, 0, 0.15), wood("#5a3520"), 0.01)]
    parts.append(box((0.16, 0.01, 0.07), (0, -0.181, 0.15), solid(metal, 0.2, 1.0), 0.004))
    shine = solid(metal, 0.12, 1.0)
    parts.append(cylinder(0.1, 0.3, 0.34, shine, bevel=0.01))
    parts.append(cylinder(0.025, 0.34, 0.5, shine))
    parts.append(cone(0.06, 0.5, 0.78, shine, top_radius=0.15))
    for side in (-1, 1):
        parts.append(torus(0.06, 0.012, (side * 0.15, 0, 0.68), shine, (math.radians(90), 0, math.radians(45))))
    return parts


def trophy_bronze():
    return trophy("#c07a3a")


def trophy_silver():
    return trophy("#d0d6de")


def trophy_gold():
    return trophy("#e8b830")


# --- Catálogo e fotos -------------------------------------------------------------------------------------------

BUILDERS = {name: obj for name, obj in globals().items() if callable(obj) and name in {
    "machine_coffee", "machine_coffee_smart", "machine_frozen", "machine_juice", "stove_moon", "train_dining", "train_locomotive",
    "train_wagon", "witch_cauldron", "arcade", "balloons", "banana_tree", "bonsai", "bookshelf", "boombox", "cactus",
    "chocolate_fountain", "claw_machine", "critic_statue", "cupcake_tree", "delivery_counter", "disco_ball", "dj_booth",
    "edison_lamp", "eiffel", "floor_lamp", "flower_vase", "giant_pumpkin", "hay_bale", "jukebox", "lava_lamp", "macrame_plant",
    "neon_diner", "olive_tree", "paper_lantern", "paris_lamp", "parrot", "party_cake", "pinata", "plant_pot", "popcorn_cart",
    "ring_toss", "stage", "station_clock", "succulents", "tree_blueberry", "tree_mango", "tree_strawberry", "trophy_bronze",
    "trophy_gold", "trophy_silver", "wagon_wheel", "wine_barrel"}}
FOOTPRINTS = {"bookshelf": (2, 1), "dj_booth": (2, 1), "stage": (2, 2)}
# Enfeites redondos que têm um lado da frente (o rosto da abóbora, o papagaio): virados para a câmera.
FACE_CAMERA = {"giant_pumpkin": 45.0, "parrot": 45.0}


def render(item_id, rotations, samples, anchors):
    footprint = FOOTPRINTS.get(item_id, (1, 1))
    for rotation in rotations:
        fx, fy = footprint if rotation % 2 == 0 else (footprint[1], footprint[0])
        width = int(128 * (fx + fy) + 180)
        cena3d.setup(samples, (width, 620), shadow_center=(fx / 2, -fy / 2),
                     shadow_size=(fx + M.SHADOW_MARGIN, fy + M.SHADOW_MARGIN))
        objects = [obj for obj in M._flatten(BUILDERS[item_id]()) if obj is not None]
        anchor, center = M.assemble(objects, footprint, rotation)
        if item_id in FACE_CAMERA:
            parent = objects[0].parent
            parent.rotation_euler.z += math.radians(FACE_CAMERA[item_id])
            bpy.context.view_layer.update()
        aim_camera((center[0], center[1], 0.62))
        name = f"{item_id}_r{rotation}"
        anchors[name] = cena3d.shoot(name, anchor, WORK)


def main():
    import json
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    samples = 24 if "rascunho" in args else 80
    wanted = [a for a in args if a in BUILDERS] or sorted(BUILDERS)
    with open(os.path.join(cena3d.SPRITES, "sprites.json"), encoding="utf-8") as source:
        manifest = json.load(source)
    anchors = {}
    for item_id in wanted:
        names = sorted(set(manifest["furniture"][item_id].values()))
        render(item_id, [int(name.rsplit("_r", 1)[1]) for name in names], samples, anchors)
        print("PRONTO", item_id, flush=True)
    cena3d.update_manifest(anchors)
    print("ENFEITES OK", len(anchors), flush=True)


if __name__ == "__main__":
    main()
