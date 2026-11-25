## Fängt Fehlermeldungen von Godot ab und reicht sie an die Debug-Anzeige weiter.
## (Max hat am Handy keine Konsole – deshalb zeigen wir Fehler direkt im Spiel.)
class_name ErrorCatcher
extends Logger

var _mutex := Mutex.new()
var _pending: Array[String] = []


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	var kind := "WARNUNG" if error_type == ERROR_TYPE_WARNING else "FEHLER"
	var text := rationale if rationale != "" else code
	_push("%s: %s  (%s:%d %s)" % [kind, text, file.get_file(), line, function])


func _log_message(message: String, error: bool) -> void:
	if error:
		_push("FEHLER: " + message.strip_edges())


## Kann aus jedem Thread aufgerufen werden, deshalb mit Mutex.
func _push(text: String) -> void:
	_mutex.lock()
	_pending.append(text)
	_mutex.unlock()


## Holt alle neuen Meldungen ab (vom Hauptthread aus).
func take() -> Array[String]:
	_mutex.lock()
	var out := _pending.duplicate()
	_pending.clear()
	_mutex.unlock()
	return out
