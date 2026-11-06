from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
root = Path(__file__).resolve().parent
out = root / 'dist'
out.mkdir(exist_ok=True)
with ZipFile(out / 'oneui-stage-bypass-0.1.0.zip', 'w', ZIP_DEFLATED) as archive:
    for path in sorted((root / 'module').iterdir()):
        if path.is_file():
            archive.write(path, path.name)
print(out / 'oneui-stage-bypass-0.1.0.zip')
