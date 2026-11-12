# Modelos de Blender por script

Los modelos se generan enteros con Python dentro de Blender 5.2, sin esculpir a mano, para que se puedan rehacer y ajustar. Se corren con el módulo `bpy` (`python3 script.py …`) o con `blender -b -P script.py -- …`.

## El Q'ispi

| Paso | Script | Resultado |
|------|--------|-----------|
| 1. Modelar en alta | `build_qispi.py` | `qispi_high.blend`: cuerpo de sal con cara tallada y cristales de halita |
| 2. Pintar | `qispi_materials.py` | Piel de sal con grietas hexagonales, cara pálida con cuencas oscuras y cristales lisos |
| 3. Hornear | `bake.py` | Malla de juego con albedo, rugosidad y normales horneadas; los cristales conservan su material |
| 4. Animar | `qispi_rig.py` | Esqueleto, pesos y animaciones `idle`, `walk`, `run`, `stunned` y `catch` |
| 5. Captura de movimiento | `qispi_mocap.py` | Cambia `walk`, `run` y `stunned` por captura real de CMU; `idle` y `catch` quedan hechas a mano |
| Revisar | `preview.py` | Vistas de frente, cara y perfil renderizadas con Cycles |

```bash
python3 build_qispi.py /ruta/qispi_high.blend
python3 qispi_materials.py /ruta/qispi_high.blend /ruta/qispi_painted.blend
python3 bake.py /ruta/qispi_painted.blend /ruta/horneado 2048 qispi
python3 qispi_rig.py /ruta/horneado/qispi_game.blend /ruta/animado
python3 qispi_mocap.py /ruta/animado/qispi_rigged.blend /ruta/cmu-mocap/data /ruta/captura
python3 preview.py /ruta/qispi_painted.blend /ruta/vista 24
```

Los BVH salen del repositorio público `una-dinosauria/cmu-mocap` (CMU Graphics Lab Motion Capture Database, de uso libre): una caminata sigilosa (77_29), una carrera (16_35) y un gesto de susto (79_73). Cada hueso copia la dirección de su par en la captura, así que da igual que las proporciones sean distintas; los ciclos se recortan a un paso completo, de un despegue del pie izquierdo al siguiente.

Del paso de captura (o del 4, si no se usa) se copian `qispi.gltf`, `qispi.bin` y los PNG a `assets/models/qispi/`. El modelo mira hacia +Y en Blender, que en Godot queda mirando a −Z (el frente).

`bake.py` sirve para cualquier modelo: la pieza principal se llama `<Nombre>High`, y las piezas con la propiedad `keep_material` se suman sin hornear.

## Texturas del salar

La sal y las tablas vienen de fotos escaneadas de Poly Haven (CC0): `tools/download_textures.py` las descarga y recolorea la sal por luminancia, para conservar el detalle real con los tonos blancos del salar.

```bash
python3 tools/download_textures.py assets/textures/salar 2k
```

La madera de cardón, con sus agujeros alargados, no existe escaneada: la hornea `salt_textures.py` sin costuras (albedo, normales y ORM, con normales y oclusión calculadas de la altura con numpy).

```bash
python3 salt_textures.py assets/textures/salar 1024
```

En Godot se usan con los materiales triplanares de `src/world/materials/` (`salt_block.tres`, `salt_crust.tres`, `planks.tres`, `cardon.tres`), que ajustan la escala a metros reales.

## Objetos del hotel

`props.py` modela la cama de bloques de sal (con colchón y frazada de aguayo), la mesa y el banco de sal, la puerta de cardón con su marco, la lámpara de kerosene, la maleta y el mostrador de la recepción. Exporta un OBJ por material a `assets/models/props/`, sin UV, porque en Godot usan materiales triplanares.

```bash
python3 props.py assets/models/props
```

Cada objeto tiene su escena en `src/world/props/`, con colisión; los que estorban el paso están en el grupo `navigation_source`.

## Personajes

`make_human.py` arma a Lucía y a Javier con [MakeHuman](http://www.makehumancommunity.org) (CC0): la malla base deformada con sus objetivos de género, edad, origen y estatura, la ropa, el pelo, los ojos y las cejas de los recursos del sistema ajustados con sus `.mhclo`, y el esqueleto por defecto con sus pesos. Las animaciones salen de la Universal Animation Library de Quaternius (CC0, `J-Ponzo/gltf-universal-animation-library`): cada hueso copia el giro de su par comparando las dos poses de descanso, así que se puede usar cualquier animación de esa biblioteca.

Cada personaje es un JSON en `characters/` con sus objetivos, su piel, sus piezas y las animaciones que lleva.

```bash
python3 make_human.py characters/lucia.json <makehuman>/makehuman/data <recursos_del_sistema> <AnimationLibrary_Godot_Standard.gltf> /ruta/lucia
```

La ruta de salida tiene que ser absoluta: el script guarda un `.blend` antes de exportar y, con una ruta relativa, las texturas teñidas quedan sin datos. Los recursos del sistema son `makehuman_system_assets_cc0.zip` de la página de paquetes de MakeHuman. Del resultado se copian el `.gltf`, el `.bin` y las imágenes que nombra a `assets/models/characters/<nombre>/`.

## El 4x4 de Javier

`build_car.py` modela la vagoneta: carrocería, cabina inclinada, parrilla con bultos, rueda de auxilio y ruedas aparte para que giren.

```bash
python3 build_car.py assets/models/car/car.gltf
```

## El cementerio de trenes

`trains.py` modela el vagón de carga (chasis y ruedas de hierro, paredes de chapa abollada y la puerta corrida a un lado del hueco), la locomotora a vapor y el altar del Tío con sus ofrendas. Los vagones y la locomotora salen como OBJ sin UV para los materiales triplanares de óxido y chapa (`rusty_metal.tres`, `corrugated.tres`); el Tío sale como glTF con sus colores.

```bash
python3 trains.py assets/models/trains assets/models/trains/tio.gltf
```

## La isla Incahuasi

La isla no necesita Blender: tres scripts con numpy en `tools/` arman sus piezas en OBJ, sin UV, para los materiales triplanares.

- `island.py` hace el cerro de coral: una cúpula con ruido, una explanada en la cima y pendientes suavizadas hasta que se pueden caminar. También escribe la forma de colisión (`HeightMapShape3D`) y los lugares para los cardones.
- `cactus.py` hace tres cardones con costillas: uno alto con tres brazos, uno mediano con dos y uno joven sin brazos.
- `boulder.py` hace dos rocas deformadas, chatas abajo, para las grietas donde esconderse y las piedras sueltas.
- `boat.py` hace el bote de Don Celestino: casco de tablas con proa en punta, popa cortada y dos bancos.

```bash
python3 tools/island.py assets/models/island/island.obj src/world/level_04/island_shape.tres src/world/level_04/cactus_spots.json
python3 tools/cactus.py assets/models/island
python3 tools/boulder.py assets/models/island
python3 tools/boat.py assets/models/island/boat.obj
```

