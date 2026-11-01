"""Peças comuns de plantas e enfeites: cone, anel, folha, folhagem, vidro, vaso e o brilho de luminária.
Os modelos dos enfeites estão em enfeites_a3d.py.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cena3d  # noqa: E402
import moveis3d as M  # noqa: E402
from moveis3d import cylinder, emission, solid, sphere  # noqa: E402



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


def _lifted(parts, dz):
    for obj in M._flatten(parts):
        obj.location.z += dz
    return parts
