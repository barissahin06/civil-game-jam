# Bağımlılık sahipliği

| Kapsam                                                    | Manifest                                              | Kilit / doğrulama              |
| --------------------------------------------------------- | ----------------------------------------------------- | ------------------------------ |
| Asset Python araçları: Pillow 12.3.0                      | `tools/pyproject.toml`                                | `tools/uv.lock`                |
| GDScript / şema: gdtoolkit 4.5.0, check-jsonschema 0.38.2 | Aynı manifest, `dev` grubu                            | Aynı kilit                     |
| JSON/Markdown/YAML: Prettier 3.9.9                        | `package.json`, `devDependencies`                     | `package-lock.json`            |
| Godot unit test: GdUnit4 6.2.2                            | `tools/pyproject.toml`, `tool.civil-game-jam.gdunit4` | Arşiv SHA-256                  |
| Aseprite MCP                                              | `tools/mcp/aseprite-mcp/pyproject.toml`               | Paket içindeki `uv.lock`       |
| Art MCP                                                   | `tools/mcp/pixelspark-art-mcp/pyproject.toml`         | Paket içindeki `uv.lock`       |
| Godot MCP                                                 | Yerel `.codex/config.toml`                            | `@coding-solo/godot-mcp@0.1.1` |

`gdformat`, `gdlint`, `gdradon` gdtoolkit ile gelir; ayrı paket veya ESLint kurulmaz.
Static typing Godot motorunun özelliğidir. İki MCP Python 3.13 ve kendi bağımsız ortamlarını kullanır;
oyun araçları MCP `.venv` ortamına bağlanmaz. MCP bağımlılıkları SDK 1.30.0 dahil kendi kilitlerindedir.

GdUnit4 indirilmeden önce arşiv hash'i doğrulanır. Var olan farklı addon üzerine yazılmaz.
İndirilen üçüncü taraf kaynakları Git dışındadır. Paket MIT lisansları MCP dizinlerinde korunur.
Makinedeki Codebase Memory, Context7, Blender ve diğer genel MCP kayıtları bu reponun
Python/Node paketleri değildir; Codex'in mevcut genel kurulumundan gelir.
