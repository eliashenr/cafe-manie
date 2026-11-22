"""Instala um staging de arte existente, preservando as demais partes do catálogo.

python tools/ia/integrar_visual_codex.py build/visual-reformulacao/retratos --install
Sem --install apenas valida. Não cria IDs nem altera dados de conteúdo.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import shutil
import tempfile
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]


def integrate(stage: Path, install: bool = False, root: Path = ROOT) -> dict:
    stage = stage.resolve()
    manifest_path = root / 'art/sprites/sprites.json'
    original = manifest_path.read_bytes()
    manifest = json.loads(original)
    patch = json.loads((stage / 'manifest_patch.json').read_text(encoding='utf-8'))
    if set(patch) - {'sprites', 'table_tops'}:
        raise ValueError('O patch só pode mudar sprites existentes e altura de tampos')
    for name, entry in patch['sprites'].items():
        if name not in manifest['sprites'] or Path(name).name != name:
            raise ValueError('Sprite desconhecido: ' + name)
        if len(entry['anchor']) != 2 or not all(math.isfinite(x) for x in entry['anchor']):
            raise ValueError('Âncora inválida: ' + name)
        if not math.isfinite(entry.get('density', 1)) or entry.get('density', 1) <= 0:
            raise ValueError('Densidade inválida: ' + name)
        with Image.open(stage / 'sprites' / (name + '.png')) as image:
            if image.mode != 'RGBA' or image.getchannel('A').getextrema()[0] != 0:
                raise ValueError('Exige PNG RGBA transparente: ' + name)
        manifest['sprites'][name] = entry
    for name, height in patch.get('table_tops', {}).items():
        if name not in manifest['furniture'] or not math.isfinite(height) or height <= 0:
            raise ValueError('Tampo inválido: ' + name)
        manifest.setdefault('table_tops', {})[name] = height
    result = {'validated': len(patch['sprites']), 'installed': install}
    if install:
        backup = stage / 'antes_instalacao'
        if backup.exists():
            raise ValueError('Backup já existe; use outro staging para uma nova revisão')
        backup.mkdir()
        (backup / 'sprites.json').write_bytes(original)
        # O backup precisa estar completo antes da primeira troca em produção.
        for name in patch['sprites']:
            target = manifest_path.parent / (name + '.png')
            shutil.copy2(target, backup / target.name)
        if manifest_path.read_bytes() != original:
            raise RuntimeError('Manifesto mudou antes da instalação; produção não alterada')
        updated = (json.dumps(manifest, ensure_ascii=False, indent=2) + '\n').encode('utf-8')
        # Temporários no mesmo volume permitem substituir cada arquivo inteiro.
        # A Godot ignora esta pasta oculta; fontes e backups ficam no staging.
        with tempfile.TemporaryDirectory(prefix='.visual_codex_', dir=manifest_path.parent) as directory:
            prepared = Path(directory)
            for name in patch['sprites']:
                shutil.copy2(stage / 'sprites' / (name + '.png'), prepared / (name + '.png'))
            prepared_manifest = prepared / 'sprites.json'
            prepared_manifest.write_bytes(updated)
            if manifest_path.read_bytes() != original:
                raise RuntimeError('Manifesto mudou antes da instalação; produção não alterada')
            replaced = []
            try:
                for name in patch['sprites']:
                    (prepared / (name + '.png')).replace(manifest_path.parent / (name + '.png'))
                    replaced.append(name)
                if manifest_path.read_bytes() != original:
                    raise RuntimeError('Manifesto mudou durante a instalação')
                # Ponto de confirmação: metadados mudam atomicamente, por último.
                prepared_manifest.replace(manifest_path)
            except BaseException as error:
                failures = []
                for name in reversed(replaced):
                    try:
                        restore = prepared / (name + '.png')
                        shutil.copy2(backup / restore.name, restore)
                        restore.replace(manifest_path.parent / restore.name)
                    except OSError as rollback_error:
                        failures.append(f'{name}: {rollback_error}')
                if failures:
                    raise RuntimeError(f'Falha ao restaurar sprites; backup em {backup}: '
                                       + '; '.join(failures)) from error
                raise
        receipt = {
            'sprites': list(patch['sprites']), 'table_tops': patch.get('table_tops', {}),
            'manifest_before_sha256': hashlib.sha256(original).hexdigest(),
            'manifest_after_sha256': hashlib.sha256(updated).hexdigest()
        }
        try:
            (stage / 'instalacao.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
        except OSError as error:
            # A arte já foi confirmada e está consistente; falha do recibo não é rollback.
            result['receipt_error'] = str(error)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('staging', type=Path)
    parser.add_argument('--install', action='store_true')
    args = parser.parse_args()
    print(json.dumps(integrate(args.staging, args.install)))


if __name__ == '__main__':
    main()
