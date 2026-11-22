"""Contrato de registro e preservação das camadas dos retratos."""
import unittest

from PIL import Image

import importar_retratos_codex as importer


class PortraitImportTests(unittest.TestCase):
    def test_registration_preserves_source_alpha_and_point_without_resampling(self):
        image = Image.new("RGBA", (32, 28))
        for x in range(4, 26):
            for y in range(3, 24):
                image.putpixel((x, y), (23, 57, 149, (x * y) % 254 + 1))
        spec = {"point_px": [11, 18], "target_ui": [70, 125], "scale_ui": 0.25}
        result, entry, info = importer.registered_layer(image, spec)
        self.assertEqual(result.tobytes(), image.crop(info["crop_px"]).tobytes())
        for axis in range(2):
            projected = importer.ANCHOR[axis] + (spec["point_px"][axis] - info["crop_px"][axis] - entry["anchor"][axis]) / 4
            self.assertAlmostEqual(projected, spec["target_ui"][axis])

    def test_explicit_framing_crops_rectangle_without_masking(self):
        image = Image.new("RGBA", (20, 20), (72, 133, 201, 37))
        result, entry, info = importer.registered_layer(image, {"point_px": [0, 0], "target_ui": [0, 0], "scale_ui": 0.25, "clip_ui": [1, 1, 4, 4]})
        self.assertEqual(result.size, (12, 12))
        self.assertEqual(result.getextrema(), ((72, 72), (133, 133), (201, 201), (37, 37)))
        self.assertEqual(info["crop_px"], [4, 4, 16, 16])
        self.assertEqual(entry["anchor"], [276, 436])

    def test_avatar_layer_order_matches_runtime(self):
        avatar = {"outfit": "branca", "skin": "clara", "hair": "curto_castanho", "hat": "toque"}
        names = importer.layer_names(avatar)
        colors = [(255, 0, 0, 255), (0, 255, 0, 255), (0, 0, 255, 255)]
        frames = {name: {"image": Image.new("RGBA", (8, 8), color), "entry": {"anchor": [0, 0], "density": 4}} for name, color in zip(names, colors)}
        image = importer.compose(frames, avatar)
        self.assertEqual(image.getpixel((280, 440)), colors[2])
        avatar["hat"] = None
        self.assertEqual(importer.compose(frames, avatar).getpixel((280, 440)), colors[1])

    def test_default_calibration_covers_exact_customization_names(self):
        config = importer.default_config()
        names = [entry["name"] for atlas in config["atlases"] for entry in atlas["entries"]]
        self.assertEqual(set(names), importer.EXPECTED)
        self.assertEqual(len(names), len(set(names)))
        for hair in importer.HAIRS:
            entries = [entry for entry in config["atlases"][0]["entries"] if entry["name"].endswith("_" + hair)]
            self.assertEqual(len({(tuple(entry["point_px"]), tuple(entry["target_ui"]), entry["scale_ui"]) for entry in entries}), 1)


if __name__ == "__main__":
    unittest.main()
