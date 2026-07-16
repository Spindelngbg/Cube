extends Node

## Lättvikts-brygga — OWDB-addon inaktiverat vid testkörning.
## Registrering är no-op tills open-world-database är fullt integrerat.


func configure_for_spawn(_spawn_id: String) -> void:
	pass


func register_runtime_entity(_node: Node3D, _scene_path: String, _peer_id: int = 1) -> void:
	pass


func unregister_runtime_entity(_node: Node) -> void:
	pass