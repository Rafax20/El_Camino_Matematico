# res://Scripts_gd/GestionAudio.gd
extends Node

signal audio_finalizado # 📢 NUEVA SEÑAL

# Configuración de ElevenLabs
const API_KEY : String = "sk_fbd7e6c9a5453b81a31cde55f2d66f868811ad53ced06d87"
const VOICE_ID : String = "vAcVPeEOlCrOxhRoCXb8"  

const CONFIG_PATH : String = "user://config_audio.cfg"

var volumen_master: float = 1.0
var volumen_musica: float = 0.8
var volumen_voz: float = 1.0
var volumen_sfx: float = 0.9

var http_request : HTTPRequest
var audio_player : AudioStreamPlayer
var sfx_player : AudioStreamPlayer
var musica_player : AudioStreamPlayer
var musica_fondo_player : AudioStreamPlayer

func _ready():
	_configurar_buses_audio()

	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "VozPlayer"
	audio_player.bus = "Voz"
	add_child(audio_player)
	audio_player.finished.connect(func(): audio_finalizado.emit())
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	musica_player = AudioStreamPlayer.new()
	musica_player.name = "MusicaPlayer"
	musica_player.bus = "Musica"
	add_child(musica_player)
	
	# 🌌 Player dedicado para la música de fondo global (independiente de musica_player)
	musica_fondo_player = AudioStreamPlayer.new()
	musica_fondo_player.name = "MusicaFondoPlayer"
	musica_fondo_player.bus = "Musica"
	add_child(musica_fondo_player)
	
	cargar_configuracion_audio()

func _configurar_buses_audio() -> void:
	if AudioServer.get_bus_index("Musica") == -1:
		var idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "Musica")
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("Voz") == -1:
		var idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "Voz")
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		var idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")

func establecer_volumen_bus(nombre_bus: String, valor_lineal: float) -> void:
	var idx = AudioServer.get_bus_index(nombre_bus)
	if idx != -1:
		if valor_lineal <= 0.01:
			AudioServer.set_bus_mute(idx, true)
		else:
			AudioServer.set_bus_mute(idx, false)
			AudioServer.set_bus_volume_db(idx, linear_to_db(clamp(valor_lineal, 0.01, 1.0)))

func establecer_volumen_master(valor: float) -> void:
	volumen_master = clamp(valor, 0.0, 1.0)
	establecer_volumen_bus("Master", volumen_master)
	guardar_configuracion_audio()

func establecer_volumen_musica(valor: float) -> void:
	volumen_musica = clamp(valor, 0.0, 1.0)
	establecer_volumen_bus("Musica", volumen_musica)
	guardar_configuracion_audio()

func establecer_volumen_voz(valor: float) -> void:
	volumen_voz = clamp(valor, 0.0, 1.0)
	establecer_volumen_bus("Voz", volumen_voz)
	guardar_configuracion_audio()

func establecer_volumen_sfx(valor: float) -> void:
	volumen_sfx = clamp(valor, 0.0, 1.0)
	establecer_volumen_bus("SFX", volumen_sfx)
	guardar_configuracion_audio()

func aplicar_volumenes() -> void:
	establecer_volumen_bus("Master", volumen_master)
	establecer_volumen_bus("Musica", volumen_musica)
	establecer_volumen_bus("Voz", volumen_voz)
	establecer_volumen_bus("SFX", volumen_sfx)

func guardar_configuracion_audio() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master", volumen_master)
	config.set_value("audio", "musica", volumen_musica)
	config.set_value("audio", "voz", volumen_voz)
	config.set_value("audio", "sfx", volumen_sfx)
	config.save(CONFIG_PATH)

func cargar_configuracion_audio() -> void:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	if err == OK:
		volumen_master = config.get_value("audio", "master", 1.0)
		volumen_musica = config.get_value("audio", "musica", 0.8)
		volumen_voz = config.get_value("audio", "voz", 1.0)
		volumen_sfx = config.get_value("audio", "sfx", 0.9)
	aplicar_volumenes()

func probar_voz() -> void:
	reproducir_audio_local(LISTA_ELOGIOS.pick_random())

func probar_sfx() -> void:
	reproducir_sfx("acierto_tv")


# 🌟 Catálogo de frases de elogio y ánimo de July (16 elogios y 16 ánimos con acentuación de México/Latinoamérica)
const LISTA_ELOGIOS: Array[String] = [
	"Elogios/elogio1",
	"Elogios/elogio2",
	"Elogios/elogio3",
	"Elogios/elogio4",
	"Elogios/elogio5",
	"Elogios/elogio6",
	"Elogios/elogio7",
	"Elogios/elogio8",
	"Elogios/elogio9",
	"Elogios/elogio10",
	"Elogios/elogio11",
	"Elogios/elogio12",
	"Elogios/elogio13",
	"Elogios/elogio14",
	"Elogios/elogio15",
	"Elogios/elogio16"
]

const LISTA_ANIMOS: Array[String] = [
	"Animos/animo1",
	"Animos/animo2",
	"Animos/animo3",
	"Animos/animo4",
	"Animos/animo5",
	"Animos/animo6",
	"Animos/animo7",
	"Animos/animo8",
	"Animos/animo9",
	"Animos/animo10",
	"Animos/animo11",
	"Animos/animo12",
	"Animos/animo13",
	"Animos/animo14",
	"Animos/animo15",
	"Animos/animo16"
]

## 🌟 Reproduce un elogio aleatorio de July (1 al 16)
func reproducir_elogio() -> void:
	reproducir_audio_local(LISTA_ELOGIOS.pick_random())

## 💙 Reproduce una frase de ánimo aleatoria de July (1 al 16)
func reproducir_animo() -> void:
	reproducir_audio_local(LISTA_ANIMOS.pick_random())

## 🔊 Para reproducir frases fijas descargadas localmente (Voz de July)
func reproducir_audio_local(nombre_archivo: String) -> void:
	# Si ya estaba sonando algo en la voz, lo detenemos
	if audio_player.playing:
		audio_player.stop()
		
	var posibles_rutas = [
		"res://Audios/" + nombre_archivo + ".mp3",
		"res://Audios/" + nombre_archivo + ".wav",
		"res://Audios/" + nombre_archivo + ".ogg",
		"res://Audios/Instrucciones/" + nombre_archivo + ".mp3",
		"res://Audios/Instrucciones/" + nombre_archivo + ".wav",
		"res://Audios/Sonidos/" + nombre_archivo + ".wav",
		"res://Audios/Sonidos/" + nombre_archivo + ".mp3"
	]
	
	if nombre_archivo == "Instrucciones/como_jugar_laboratorio":
		posibles_rutas.append("res://Audios/Laboratorio.mp3")
	elif nombre_archivo.to_lower() == "laboratorio":
		posibles_rutas.append("res://Audios/Instrucciones/como_jugar_laboratorio.mp3")
	
	var ruta_encontrada = ""
	for r in posibles_rutas:
		if ResourceLoader.exists(r):
			ruta_encontrada = r
			break
	
	if ruta_encontrada != "":
		var stream = load(ruta_encontrada)
		audio_player.stream = stream
		audio_player.play()
		print("🔊 Reproduciendo audio local: ", nombre_archivo)
	else:
		print("❌ Error: El archivo de audio local no existe en la ruta: ", nombre_archivo)

## 💥 Para reproducir efectos de sonido (láser, aciertos, clics) sin interrumpir la voz
func reproducir_sfx(nombre_archivo: String, volumen_db: float = 0.0) -> void:
	var posibles_rutas = [
		"res://Audios/Sonidos/" + nombre_archivo + ".wav",
		"res://Audios/Sonidos/" + nombre_archivo + ".mp3",
		"res://Audios/" + nombre_archivo + ".wav",
		"res://Audios/" + nombre_archivo + ".mp3"
	]
	
	var ruta_encontrada = ""
	for r in posibles_rutas:
		if ResourceLoader.exists(r):
			ruta_encontrada = r
			break
			
	if ruta_encontrada != "":
		var stream = load(ruta_encontrada)
		sfx_player.stream = stream
		sfx_player.volume_db = volumen_db
		sfx_player.play()
		print("🔊 SFX reproducido: ", nombre_archivo)
	else:
		print("❌ Error: SFX no encontrado: ", nombre_archivo)

## 🎵 Para reproducir música o sonido ambiental en bucle
func reproducir_musica(nombre_archivo: String, volumen_db: float = -12.0) -> void:
	var posibles_rutas = [
		"res://Audios/Sonidos/" + nombre_archivo + ".wav",
		"res://Audios/Sonidos/" + nombre_archivo + ".mp3",
		"res://Audios/Sonidos/" + nombre_archivo + ".ogg",
		"res://Audios/" + nombre_archivo + ".wav",
		"res://Audios/" + nombre_archivo + ".mp3",
		"res://Audios/" + nombre_archivo + ".ogg"
	]
	
	var ruta_encontrada = ""
	for r in posibles_rutas:
		if ResourceLoader.exists(r):
			ruta_encontrada = r
			break
			
	if ruta_encontrada != "":
		var stream = load(ruta_encontrada)
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = stream.data.size() / 2
		musica_player.stream = stream
		musica_player.volume_db = volumen_db
		musica_player.play()
		print("🎵 Música en bucle iniciada: ", nombre_archivo)
	else:
		print("❌ Error: Música no encontrada: ", nombre_archivo)

func detener_musica() -> void:
	if musica_player and musica_player.playing:
		musica_player.stop()
		print("🎵 Música detenida.")

## 🌌 Inicia la música de fondo global en bucle (no interfiere con musica_player del Buscador)
func iniciar_musica_global(volumen_db: float = -18.0) -> void:
	if musica_fondo_player == null or not is_instance_valid(musica_fondo_player):
		return
	# Evitar reiniciar si ya está sonando
	if musica_fondo_player.playing:
		return
	var ruta = "res://Audios/Sonidos/musica_fondo_global.wav"
	if not ResourceLoader.exists(ruta):
		print("❌ musica_fondo_global.wav no encontrado")
		return
	var stream = load(ruta)
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2
	musica_fondo_player.stream = stream
	musica_fondo_player.volume_db = volumen_db
	musica_fondo_player.play()
	print("🌌 Música de fondo global iniciada.")

## 🌌 Detiene la música de fondo global
func detener_musica_global() -> void:
	if musica_fondo_player and musica_fondo_player.playing:
		musica_fondo_player.stop()
		print("🌌 Música de fondo global detenida.")


func decir_frase(texto: String) -> void:
	if audio_player.playing:
		audio_player.stop()
		
	var url = "https://api.elevenlabs.io/v1/text-to-speech/" + VOICE_ID
	var headers = ["accept: audio/mpeg", "xi-api-key: " + API_KEY, "Content-Type: application/json"]
	var body = JSON.stringify({
		"text": texto,
		"model_id": "eleven_multilingual_v2",
		"voice_settings": {"stability": 0.5, "similarity_boost": 0.75}
	})
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("❌ Error al iniciar la petición TTS: ", error)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var stream = AudioStreamMP3.new()
		stream.data = body
		audio_player.stream = stream
		audio_player.play()
		print("📥 Audio dinámico de July reproducido con éxito.")
	else:
		print("❌ Error en ElevenLabs (Código: ", response_code, ")")
