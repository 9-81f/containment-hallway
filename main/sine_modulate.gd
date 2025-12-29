extends CanvasModulate

var amp := 1.0
var freq := 2.0
var time := 0.0

func  _ready() -> void:
	color = Color(1.0, 1.0, 1.0, 1.0)

func _physics_process(delta: float) -> void:
	time += delta
	var wave = sin(time * freq) * amp

	color.g = absf(wave) 
	color.b = absf(wave)
