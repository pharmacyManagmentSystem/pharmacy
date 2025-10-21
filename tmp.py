from pathlib import Path
path = Path('lib/models/product.dart')
text = path.read_text()
needle = "      'imageUrl': imageUrl;"
print(text[:50])