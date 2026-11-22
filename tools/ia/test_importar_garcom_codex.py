"""Contrato do importador; fixtures geométricas descartáveis, sem arte de produção."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

from PIL import Image, ImageDraw


HERE = Path(__file__).resolve().parent
MODULE = importlib.util.spec_from_file_location("importar_garcom_codex", HERE / "importar_garcom_codex.py")
IMPORTER = importlib.util.module_from_spec(MODULE)
MODULE.loader.exec_module(IMPORTER)


class ImporterTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="cafe-garcom-import-test-")
        self.folder = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def fixture(self, view="frente", carrying=False, duplicate=False):
        sheet = Image.new("RGBA", (240, 300))
        for i in range(9):
            x, y = (i % 3) * 80, (i // 3) * 100
            draw = ImageDraw.Draw(sheet)
            dy = 0 if duplicate else (i % 3) * 2
            tint = 60 if duplicate else 60 + i * 8
            draw.rectangle((x + 28, y + 25 + dy, x + 50, y + 74 + dy), fill=(tint, 40, 20, 255))
            if carrying:
                draw.rectangle((x + 49, y + 40 + dy, x + 65, y + 44 + dy), fill=(90, 100, 115, 255))
        filename = f"{view}_{carrying}.png"
        sheet.save(self.folder / filename)
        frames = [{} for _ in range(9)]
        if carrying:
            frames = [{"tray": [57, 40 + (i % 3) * 2, 16]} for i in range(9)]
        return {"file": filename, "view": view, "carrying": carrying,
                "anchor": [40, 80], "reference_height_px": 50, "frames": frames}

    def test_common_scale_and_anchor_preserve_authored_vertical_motion(self):
        frames = IMPORTER.import_sheet(self.fixture(), self.folder)
        first, second = frames[:2]
        self.assertEqual(first["source"]["scale"], second["source"]["scale"])
        # O segundo desenho foi colocado 2 px abaixo; a âncora recortada tem de
        # preservar esse movimento, não recentralizar os pés em cada quadro.
        shift_world = (first["entry"]["anchor"][1] - second["entry"]["anchor"][1]) / 4
        self.assertAlmostEqual(shift_world, 2 * 96 / 50, delta=0.3)
        self.assertTrue(first["entry"]["authored_motion"])
        self.assertTrue(first["entry"]["external_shadow"])

    def test_idle_tray_uses_explicit_measurement_and_legacy_default(self):
        frames = IMPORTER.import_sheet(self.fixture(carrying=True), self.folder)
        idle = frames[8]
        sx, sy = idle["source"]["scale"]
        self.assertEqual(idle["entry"]["tray"], [round(17 * sx / 4, 3), round(-36 * sy / 4, 3), round(16 * sx / 4, 3)])
        self.assertEqual(IMPORTER.manifest_patch(frames)["characters"]["tray_food"], idle["entry"]["tray"])

    def test_missing_tray_opaque_background_and_duplicate_steps_are_rejected(self):
        spec = self.fixture(carrying=True)
        spec["frames"][8] = {}
        with self.assertRaisesRegex(ValueError, "falta tray"):
            IMPORTER.import_sheet(spec, self.folder)
        spec = self.fixture()
        image_path = self.folder / spec["file"]
        with Image.open(image_path) as source:
            source.convert("RGB").save(image_path)
        with self.assertRaisesRegex(ValueError, "transparente"):
            IMPORTER.import_sheet(spec, self.folder)
        spec = self.fixture(duplicate=True)
        with self.assertRaisesRegex(ValueError, "oito quadros distintos"):
            IMPORTER.import_sheet(spec, self.folder)

    def test_explicit_registration_changes_anchor_and_tray_together(self):
        spec = self.fixture(carrying=True)
        before = IMPORTER.import_sheet(spec, self.folder)[0]
        spec["frames"][0]["registration"] = [2, 3]
        after = IMPORTER.import_sheet(spec, self.folder)[0]
        self.assertEqual(before["image"].tobytes(), after["image"].tobytes())
        self.assertAlmostEqual(before["entry"]["anchor"][0] - after["entry"]["anchor"][0], 2 * after["source"]["scale"][0], places=3)
        self.assertAlmostEqual(after["entry"]["tray"][0] - before["entry"]["tray"][0], 2 * after["source"]["scale"][0] / 4, places=3)

    def test_mirror_preserves_pose_order_and_reflects_tray_and_anchor(self):
        spec = self.fixture(carrying=True)
        before = IMPORTER.import_sheet(spec, self.folder)
        spec["mirror"] = True
        after = IMPORTER.import_sheet(spec, self.folder)
        for original, mirrored in zip(before, after):
            self.assertEqual(original["name"], mirrored["name"])
            self.assertEqual(original["image"].transpose(Image.Transpose.FLIP_LEFT_RIGHT).tobytes(), mirrored["image"].tobytes())
            self.assertAlmostEqual(original["image"].width - original["entry"]["anchor"][0], mirrored["entry"]["anchor"][0], places=3)
            self.assertEqual(-original["entry"]["tray"][0], mirrored["entry"]["tray"][0])
            self.assertEqual(original["entry"]["tray"][1:], mirrored["entry"]["tray"][1:])

    def test_portrait_preserves_aspect_alpha_and_restricts_manifest_name(self):
        image = Image.new("RGBA", (100, 100))
        ImageDraw.Draw(image).rectangle((20, 10, 59, 89), fill=(90, 70, 50, 128))
        image.save(self.folder / "icone.png")
        portrait = IMPORTER.import_portrait({"file": "icone.png", "target_size": 256}, self.folder)
        self.assertEqual(portrait["image"].size, (128, 256))
        self.assertEqual(portrait["image"].getchannel("A").getextrema(), (128, 128))
        self.assertEqual(portrait["entry"], {"anchor": [64, 128], "density": 4})
        self.assertEqual(set(IMPORTER.manifest_patch([], portrait)["sprites"]), {"icone_garcom"})
        portrait["name"] = "retrato_papai_noel"
        with self.assertRaisesRegex(ValueError, "único retrato"):
            IMPORTER.manifest_patch([], portrait)

    def test_install_only_replaces_waiter_and_two_legacy_defaults(self):
        frames = []
        for view in IMPORTER.VIEWS:
            for carrying in (False, True):
                frames.extend(IMPORTER.import_sheet(self.fixture(view, carrying), self.folder))
        root = self.folder / "project"
        destination = root / "art" / "sprites"
        destination.mkdir(parents=True)
        before = {"sprites": {"santa_oven_r0": {"anchor": [128, 301]}},
                  "characters": {"waiter": "garcom", "customers": ["cliente_01"], "tray_food": [1, 2, 3]},
                  "furniture": {"santa_oven": {"0": "santa_oven_r0"}}, "density": 2}
        IMPORTER.write_json(destination / "sprites.json", before)
        staging = self.folder / "staging"
        (staging / "sprites").mkdir(parents=True)
        for frame in frames:
            frame["image"].save(staging / "sprites" / (frame["name"] + ".png"))
        IMPORTER.install(frames, staging, root)
        after = IMPORTER.read_json(destination / "sprites.json")
        self.assertTrue((destination / "sprites.json").read_text(encoding="utf-8").startswith('{\n "sprites":'))
        self.assertEqual(after["sprites"]["santa_oven_r0"], before["sprites"]["santa_oven_r0"])
        self.assertEqual(after["furniture"], before["furniture"])
        self.assertEqual(after["characters"]["customers"], ["cliente_01"])
        self.assertEqual(after["density"], 2)
        self.assertEqual(len(list(destination.glob("garcom_*.png"))), 36)
        snapshot = (destination / "sprites.json").read_bytes()
        bad = copy.deepcopy(frames)
        bad[0]["name"] = "cliente_01_frente_em_pe"
        with self.assertRaisesRegex(ValueError, "exatamente as 36"):
            IMPORTER.install(bad, staging, root)
        self.assertEqual((destination / "sprites.json").read_bytes(), snapshot)


if __name__ == "__main__":
    unittest.main()
