# Modelos de Blender por script

Los modelos se generan enteros con Python dentro de Blender 5.2, sin esculpir a mano, para que se puedan rehacer y ajustar. Se corren con el módulo `bpy` (`python3 script.py …`) o con `blender -b -P script.py -- …`.

## El Q'ispi

| Paso | Script | Resultado |
|------|--------|-----------|
| 1. Modelar en alta | `build_qispi.py` | `qispi_high.blend`: cuerpo de sal con cara tallada y cristales de halita |
| 2. Pintar | `qispi_materials.py` | Piel de sal con grietas hexagonales, cara pálida con cuencas oscuras y cristales lisos |
| 3. Hornear | `bake.py` | Malla de juego con albedo, rugosidad y normales horneadas; los cristales conservan su material |
| 4. Animar | `qispi_rig.py` | Esqueleto, pesos y animaciones `idle`, `walk`, `run`, `stunned` y `catch` |
| Revisar | `preview.py` | Vistas de frente, cara y perfil renderizadas con Cycles |

```bash
python3 build_qispi.py /ruta/qispi_high.blend
python3 qispi_materials.py /ruta/qispi_high.blend /ruta/qispi_painted.blend
python3 bake.py /ruta/qispi_painted.blend /ruta/horneado 2048 qispi
python3 qispi_rig.py /ruta/horneado/qispi_game.blend /ruta/animado
python3 preview.py /ruta/qispi_painted.blend /ruta/vista 24
```

Del último paso se copian `qispi.gltf`, `qispi.bin` y los PNG a `assets/models/qispi/`. El modelo mira hacia +Y en Blender, que en Godot queda mirando a −Z (el frente).

`bake.py` sirve para cualquier modelo: la pieza principal se llama `<Nombre>High`, y las piezas con la propiedad `keep_material` se suman sin hornear.

## Texturas del salar

`salt_textures.py` hornea texturas repetibles sin costuras: bloques de sal del hotel (con estratos y juntas), la costra hexagonal del salar y madera de cardón con sus agujeros. Saca albedo, normales y ORM (oclusión y rugosidad); las normales y la oclusión salen de la altura, calculadas con numpy.

```bash
python3 salt_textures.py assets/textures/salar 1024
```

En Godot se usan con los materiales triplanares de `src/world/materials/` (`salt_block.tres`, `salt_crust.tres`, `cardon.tres`), que ajustan la escala a metros reales.

## Objetos del hotel

`props.py` modela la cama de bloques de sal (con colchón y frazada de aguayo), la mesa y el banco de sal, la puerta de cardón con su marco, la lámpara de kerosene, la maleta y el mostrador de la recepción. Exporta un OBJ por material a `assets/models/props/`, sin UV, porque en Godot usan materiales triplanares.

```bash
python3 props.py assets/models/props
```

Cada objeto tiene su escena en `src/world/props/`, con colisión; los que estorban el paso están en el grupo `navigation_source`.
