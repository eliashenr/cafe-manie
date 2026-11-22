"""Contratos de escala, assento e instalação; fixtures geométricas descartáveis."""
import copy
import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest

from PIL import Image, ImageDraw


HERE = Path(__file__).resolve().parent
MODULE = importlib.util.spec_from_file_location("importar_clientes_codex", HERE / "importar_clientes_codex.py")
CUSTOMERS = importlib.util.module_from_spec(MODULE)
MODULE.loader.exec_module(CUSTOMERS)


class CustomerImporterTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="cafe-clientes-import-test-")
        self.folder = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def fixture(self):
        sheet = Image.new("RGBA", (320, 600))
        for index in range(24):
            x, y = (index % 4) * 80, (index // 4) * 100
            dy = index % 3
            seated = index >= 18
            ImageDraw.Draw(sheet).rectangle((x + 25, y + 15 + dy, x + 48, y + (54 if seated else 74) + dy),
                                            fill=(45 + index * 7, 60, 35, 255))
        sheet.save(self.folder / "cliente_01.png")
        return {"look": "cliente_01", "file": "cliente_01.png", "height_world": 96,
                "groups": {"frente": {"anchor": [40, 80], "reference_height_px": 60},
                           "costas": {"anchor": [40, 80]},
                           "sentado_frente": {"seat_point_px": [37, 42]},
                           "sentado_costas_r1": {"seat_point_px": [37, 42]},
                           "sentado_costas_r2": {"seat_point_px": [37, 42]}}}

    def test_mapping_metadata_and_inherited_seated_scale(self):
        frames = CUSTOMERS.import_customer(self.fixture(), self.folder)
        self.assertEqual(frames[8]["name"], "cliente_01_costas_passo_0")
        self.assertEqual(frames[16]["name"], "cliente_01_frente_em_pe")
        self.assertEqual(frames[17]["name"], "cliente_01_costas_em_pe")
        self.assertEqual(frames[18]["name"], "cliente_01_sentado_feliz")
        self.assertEqual(frames[23]["name"], "cliente_01_sentado_costas_r2")
        for frame in frames:
            self.assertTrue(frame["entry"]["authored_motion"])
            self.assertEqual(frame["entry"]["external_shadow"], frame["index"] < 18)
            self.assertEqual(frame["source"]["scale"], frames[16]["source"]["scale"])
        self.assertLess(frames[18]["image"].height, frames[16]["image"].height)

    def test_seat_contact_lands_on_chair_target_even_when_mirrored(self):
        spec = self.fixture()
        spec["groups"]["sentado_costas_r1"]["mirror"] = True
        frames = CUSTOMERS.import_customer(spec, self.folder)
        for index in (18, 22, 23):
            frame = frames[index]
            sx, sy = frame["source"]["scale"]
            # Recria apenas a posição do ponto de contato após o recorte, não a âncora.
            cell = Image.open(self.folder / spec["file"]).crop(frame["source"]["cell"])
            scaled = cell.resize((round(cell.width * sx), round(cell.height * sy)), Image.Resampling.LANCZOS)
            px, py = 37 * sx, 42 * sy
            if frame["source"]["mirror"]:
                scaled = scaled.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                px = scaled.width - px
            crop = scaled.getchannel("A").getbbox()
            actual = ((px - crop[0] - frame["entry"]["anchor"][0]) / 4,
                      (py - crop[1] - frame["entry"]["anchor"][1]) / 4)
            for got, expected in zip(actual, frame["source"]["seat_target_world"]):
                self.assertAlmostEqual(got, expected, places=3)
            self.assertGreater(frame["entry"]["anchor"][1], frame["image"].height)

    def test_registration_preserves_authored_motion_and_back_reference_is_explicit(self):
        spec = self.fixture()
        frames = CUSTOMERS.import_customer(spec, self.folder)
        delta = (frames[0]["entry"]["anchor"][1] - frames[1]["entry"]["anchor"][1]) / 4
        self.assertAlmostEqual(delta, 96 / 60, delta=0.3)
        spec["groups"]["costas"]["reference_height_px"] = 80
        spec["groups"]["sentado_frente"]["scale_multiplier"] = 1.1
        scaled = CUSTOMERS.import_customer(spec, self.folder)
        self.assertAlmostEqual(scaled[8]["source"]["scale"][0] / frames[8]["source"]["scale"][0], .75, places=2)
        self.assertAlmostEqual(scaled[18]["source"]["scale"][0] / frames[18]["source"]["scale"][0], 1.1, places=2)
        self.assertEqual(scaled[0]["source"]["scale"], frames[0]["source"]["scale"])

    def test_analysis_reports_geometry_without_writing_assets(self):
        spec = self.fixture()
        before = set(self.folder.iterdir())
        report = CUSTOMERS.analyze(self.folder / spec["file"])
        self.assertEqual(report["grid"], [4, 6])
        self.assertEqual(len(report["frames"]), 24)
        self.assertEqual(report["frames"][16]["pose"], "frente_em_pe")
        self.assertGreater(report["frames"][16]["upper_band_width_px"], 0)
        self.assertEqual(set(self.folder.iterdir()), before)

    def test_front_scale_calibration_is_inherited_by_default(self):
        spec = self.fixture()
        spec["groups"]["frente"]["scale_multiplier"] = 1.1
        frames = CUSTOMERS.import_customer(spec, self.folder)
        for frame in frames:
            self.assertEqual(frame["source"]["scale"], frames[16]["source"]["scale"])

    def test_alternate_seated_source_keeps_walks_cells_and_registration(self):
        spec = self.fixture()
        spec["cells"] = [[c * 80, r * 100, 80, 100] for r in range(6) for c in range(4)]
        spec["cells"][22], spec["cells"][23] = spec["cells"][23], spec["cells"][22]
        original = CUSTOMERS.import_customer(spec, self.folder)
        alternate = Image.new("RGBA", (240, 200))
        for index in range(6):
            x, y = index % 3 * 80, index // 3 * 100
            ImageDraw.Draw(alternate).rectangle((x + 29, y + 12, x + 52, y + 65),
                                                fill=(20, 150 + index, 90, 255))
        alternate_path = self.folder / "cliente_01_sentados.png"
        alternate.save(alternate_path)
        seated_cells = [[0, 0, 80, 100] for _ in range(18)] + [[c * 80, r * 100, 80, 100] for r in range(2) for c in range(3)]
        for group in ("sentado_frente", "sentado_costas_r1", "sentado_costas_r2"):
            spec["groups"][group]["file"] = alternate_path.name
            spec["groups"][group]["cells"] = copy.deepcopy(seated_cells)
        # Mesma folha, mapeamento diferente por grupo: não reutiliza o cache errado.
        for group in ("sentado_costas_r1", "sentado_costas_r2"):
            cells = spec["groups"][group]["cells"]
            cells[22], cells[23] = cells[23], cells[22]
        mixed = CUSTOMERS.import_customer(spec, self.folder)
        for index in range(18):
            self.assertEqual(CUSTOMERS.pixel_hash(mixed[index]["image"]), CUSTOMERS.pixel_hash(original[index]["image"]))
            self.assertEqual(mixed[index]["entry"], original[index]["entry"])
            self.assertEqual(mixed[index]["source"], original[index]["source"])
        for index in range(18, 24):
            self.assertEqual(mixed[index]["source"]["file"], str(alternate_path.resolve()))
            self.assertEqual(mixed[index]["source"]["sha256"], hashlib.sha256(alternate_path.read_bytes()).hexdigest())
            self.assertEqual(mixed[index]["source"]["scale"], original[index]["source"]["scale"])
            self.assertNotEqual(CUSTOMERS.pixel_hash(mixed[index]["image"]), CUSTOMERS.pixel_hash(original[index]["image"]))
        self.assertEqual(mixed[22]["source"]["cell"], [160, 100, 240, 200])
        self.assertEqual(mixed[22]["image"].getpixel((mixed[22]["image"].width // 2, mixed[22]["image"].height // 2)),
                         (20, 155, 90, 255))
        self.assertEqual(mixed[23]["source"]["cell"], [80, 100, 160, 200])
        spec["frames"] = [{} for _ in range(24)]
        spec["frames"][18] = {"registration": [3, -2]}
        registered = CUSTOMERS.import_customer(spec, self.folder)
        self.assertEqual(CUSTOMERS.pixel_hash(registered[18]["image"]), CUSTOMERS.pixel_hash(mixed[18]["image"]))
        for axis, delta in enumerate((-3, 2)):
            shift = registered[18]["entry"]["anchor"][axis] - mixed[18]["entry"]["anchor"][axis]
            self.assertAlmostEqual(shift, delta * mixed[18]["source"]["scale"][axis], places=3)

    def test_invalid_ids_and_repeated_walk_frames_are_rejected(self):
        for look in ("garcom", "cliente_00", "cliente_13", "../cliente_01"):
            with self.assertRaises(ValueError):
                CUSTOMERS.expected_names(look)
        spec = self.fixture()
        frames = CUSTOMERS.import_customer(spec, self.folder)
        frames[1]["image"] = frames[0]["image"].copy()
        with self.assertRaisesRegex(ValueError, "oito passos distintos"):
            CUSTOMERS.validate(frames)
        spec["groups"]["sentado_frente"]["reference_height_px"] = 40
        with self.assertRaisesRegex(ValueError, "herdam a escala frontal"):
            CUSTOMERS.import_customer(spec, self.folder)

    def test_install_preserves_waiter_events_and_manifest_format(self):
        frames = CUSTOMERS.import_customer(self.fixture(), self.folder)
        root, staging = self.folder / "project", self.folder / "staging"
        destination = root / "art" / "sprites"
        destination.mkdir(parents=True)
        (staging / "sprites").mkdir(parents=True)
        before = {"density": 2, "sprites": {"garcom_frente_em_pe": {"anchor": [44, 90]},
                   "santa_oven_r0": {"anchor": [128, 301]}},
                  "characters": {"waiter": "garcom", "customers": ["cliente_01"], "tray_food": [1, 2, 3]},
                  "furniture": {"santa_oven": {"0": "santa_oven_r0"}}}
        CUSTOMERS.write_json(destination / "sprites.json", before)
        for frame in frames:
            frame["image"].save(staging / "sprites" / (frame["name"] + ".png"))
        CUSTOMERS.install(frames, staging, root)
        after = CUSTOMERS.read_json(destination / "sprites.json")
        self.assertEqual(after["characters"], before["characters"])
        self.assertEqual(after["furniture"], before["furniture"])
        self.assertEqual(after["sprites"]["garcom_frente_em_pe"], before["sprites"]["garcom_frente_em_pe"])
        self.assertEqual(after["sprites"]["santa_oven_r0"], before["sprites"]["santa_oven_r0"])
        self.assertEqual(len(list(destination.glob("cliente_01_*.png"))), 24)
        self.assertTrue((destination / "sprites.json").read_text().startswith('{\n "density":'))
        snapshot = (destination / "sprites.json").read_bytes()
        bad = copy.deepcopy(frames)
        bad[0]["name"] = "garcom_frente_em_pe"
        with self.assertRaisesRegex(ValueError, "24 poses completas"):
            CUSTOMERS.install(bad, staging, root)
        self.assertEqual((destination / "sprites.json").read_bytes(), snapshot)


if __name__ == "__main__":
    unittest.main()
