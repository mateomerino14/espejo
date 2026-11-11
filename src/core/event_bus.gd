extends Node
## Bus de eventos global (autoload "EventBus").
##
## Conecta sistemas que no deben conocerse entre sí: el jugador emite ruido y el ente y el HUD
## escuchan sin tener referencias directas a él.
##
## Regla: solo eventos que cruzan sistemas. La comunicación dentro de una misma escena usa
## señales locales.

## Un sonido que el ente puede oír. [param loudness] va de 0.0 a 1.0.
signal noise_emitted(origin: Vector3, loudness: float)

## El aliento de Lucía cambió.
signal stamina_changed(current: float, maximum: float)

## Lucía levantó o bajó la cámara.
signal camera_raised(is_raised: bool)

## La batería del flash cambió.
signal camera_battery_changed(current: float, maximum: float)

## Cambió cuántas fotos quedan en el rollo.
signal film_changed(remaining: int, capacity: int)

## Se tomó una foto; el álbum la guarda.
signal photo_taken(photo: Photo)
