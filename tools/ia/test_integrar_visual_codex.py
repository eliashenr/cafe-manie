"""Falhas reais de instalação em fixtures temporárias, nunca nos assets do jogo."""
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image

MODULE = importlib.util.spec_from_file_location('integrar_visual_codex',
    Path(__file__).resolve().with_name('integrar_visual_codex.py'))
INTEGRATOR = importlib.util.module_from_spec(MODULE)
MODULE.loader.exec_module(INTEGRATOR)


class VisualIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='cafe-visual-install-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.assets = self.root / 'art/sprites'
        self.assets.mkdir(parents=True)
        self.stage = self.root / 'staging'
        (self.stage / 'sprites').mkdir(parents=True)
        self.manifest_path = self.assets / 'sprites.json'
        self.manifest = {
            'density': 2, 'characters': {'waiter': ['keep']},
            'furniture': {'table': {'rotations': ['a', 'b']}},
            'table_tops': {'table': 32, 'unaffected': 20},
            'sprites': {'a': {'anchor': [1, 2]}, 'b': {'anchor': [3, 4]},
                        'keep': {'anchor': [5, 6], 'density': 4, 'authored_motion': True}},
        }
        self.manifest_path.write_text(json.dumps(self.manifest), encoding='utf-8')
        for name, color in [('a', 'red'), ('b', 'green'), ('keep', 'blue')]:
            image = Image.new('RGBA', (8, 8))
            image.paste(color, (2, 2, 6, 6))
            image.save(self.assets / (name + '.png'))
        for name, color in [('a', 'yellow'), ('b', 'purple')]:
            image = Image.new('RGBA', (12, 12))
            image.paste(color, (2, 2, 10, 10))
            image.save(self.stage / 'sprites' / (name + '.png'))
        self.patch = {'sprites': {'a': {'anchor': [7, 8], 'density': 4},
                                 'b': {'anchor': [9, 10], 'density': 4}},
                      'table_tops': {'table': 35}}
        (self.stage / 'manifest_patch.json').write_text(json.dumps(self.patch), encoding='utf-8')
        self.original = {p.name: p.read_bytes() for p in self.assets.iterdir()}

    def install(self):
        return INTEGRATOR.integrate(self.stage, True, self.root)

    def assert_original(self):
        self.assertEqual({p.name: p.read_bytes() for p in self.assets.iterdir()}, self.original)

    def test_validation_does_not_mutate_assets_or_create_backup(self):
        self.assertEqual(INTEGRATOR.integrate(self.stage, False, self.root), {'validated': 2, 'installed': False})
        self.assert_original()
        self.assertFalse((self.stage / 'antes_instalacao').exists())

    def test_success_changes_only_requested_images_and_metadata(self):
        self.assertEqual(self.install(), {'validated': 2, 'installed': True})
        installed = json.loads(self.manifest_path.read_text())
        expected = json.loads(json.dumps(self.manifest))
        expected['sprites'].update(self.patch['sprites'])
        expected['table_tops'].update(self.patch['table_tops'])
        self.assertEqual(installed, expected)
        for name in ('a', 'b'):
            self.assertEqual((self.assets / (name+'.png')).read_bytes(),
                             (self.stage / 'sprites' / (name+'.png')).read_bytes())
        self.assertEqual((self.assets/'keep.png').read_bytes(), self.original['keep.png'])
        for name, data in self.original.items():
            if name != 'keep.png':
                self.assertEqual((self.stage/'antes_instalacao'/name).read_bytes(), data)

    def test_backup_failure_does_not_start_replacing_images(self):
        real_copy = shutil.copy2
        def fail_second_backup(source, destination, *args, **kwargs):
            if Path(destination).parent.name == 'antes_instalacao' and Path(source).name == 'b.png':
                raise PermissionError('backup indisponível')
            return real_copy(source, destination, *args, **kwargs)
        with patch.object(INTEGRATOR.shutil, 'copy2', side_effect=fail_second_backup):
            with self.assertRaises(PermissionError):
                self.install()
        self.assert_original()

    def test_source_copy_failure_does_not_leave_first_image_installed(self):
        real_copy = shutil.copy2
        def fail_second_source(source, destination, *args, **kwargs):
            if Path(source) == self.stage/'sprites/b.png':
                raise PermissionError('fonte indisponível')
            return real_copy(source, destination, *args, **kwargs)
        with patch.object(INTEGRATOR.shutil, 'copy2', side_effect=fail_second_source):
            with self.assertRaises(PermissionError):
                self.install()
        self.assert_original()

    def test_second_image_replace_failure_restores_first_image(self):
        real_replace = Path.replace
        def fail_second_replace(source, destination):
            if Path(destination) == self.assets/'b.png':
                raise PermissionError('destino bloqueado')
            return real_replace(source, destination)
        with patch.object(Path, 'replace', new=fail_second_replace):
            with self.assertRaises(PermissionError):
                self.install()
        self.assert_original()

    def test_manifest_commit_failure_restores_all_images(self):
        real_replace = Path.replace
        def fail_manifest(source, destination):
            if Path(destination) == self.manifest_path:
                raise PermissionError('manifesto bloqueado')
            return real_replace(source, destination)
        with patch.object(Path, 'replace', new=fail_manifest):
            with self.assertRaises(PermissionError):
                self.install()
        self.assert_original()

    def test_concurrent_manifest_change_before_install_preserves_other_writer(self):
        real_copy = shutil.copy2
        concurrent = b'{"concurrent": true}'
        def change_during_backup(source, destination, *args, **kwargs):
            result = real_copy(source, destination, *args, **kwargs)
            if Path(destination) == self.stage/'antes_instalacao/b.png':
                self.manifest_path.write_bytes(concurrent)
            return result
        with patch.object(INTEGRATOR.shutil, 'copy2', side_effect=change_during_backup):
            with self.assertRaisesRegex(RuntimeError, 'antes da instalação'):
                self.install()
        self.original['sprites.json'] = concurrent
        self.assert_original()

    def test_concurrent_manifest_change_during_install_rolls_back_images(self):
        real_replace = Path.replace
        concurrent = b'{"concurrent": true}'
        def change_after_image(source, destination):
            result = real_replace(source, destination)
            if Path(destination) == self.assets/'b.png':
                self.manifest_path.write_bytes(concurrent)
            return result
        with patch.object(Path, 'replace', new=change_after_image):
            with self.assertRaisesRegex(RuntimeError, 'durante a instalação'):
                self.install()
        self.original['sprites.json'] = concurrent
        self.assert_original()


if __name__ == '__main__':
    unittest.main()
