# res://Scripts_gd/GestionAudio.gd
extends Node

signal audio_finalizado # 📢 NUEVA SEÑAL

# Configuración de ElevenLabs
const API_KEY : String = "sk_35961d2cccee5f5e52f5c760b9f52f95ebfe236a10cae5f3"
const VOICE_ID : String = "vAcVPeEOlCrOxhRoCXb8"  

var http_request : HTTPRequest
var audio_player : AudioStreamPlayer
var sfx_player : AudioStreamPlayer
var musica_player : AudioStreamPlayer

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "VozPlayer"
	add_child(audio_player)
	audio_player.finished.connect(func(): audio_finalizado.emit())
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	add_child(sfx_player)
	
	musica_player = AudioStreamPlayer.new()
	musica_player.name = "MusicaPlayer"
	add_child(musica_player)

# 🌟 Catálogo de frases de elogio y ánimo de July
const LISTA_ELOGIOS: Array[String] = [
	"Elogios/elogio1",
	"Elogios/elogio2",
	"Elogios/elogio3",
	"Elogios/elogio4",
	"Elogios/elogio5",
	"Elogios/elogio6",
	"Elogios/elogio7",
	"Elogios/elogio8"
]

const LISTA_ANIMOS: Array[String] = [
	"Animos/animo1",
	"Animos/animo2",
	"Animos/animo3",
	"Animos/animo4",
	"Animos/animo5",
	"Animos/animo6",
	"Animos/animo7",
	"Animos/animo8"
]

## 🌟 Reproduce un elogio aleatorio de July (1 al 8)
func reproducir_elogio() -> void:
	reproducir_audio_local(LISTA_ELOGIOS.pick_random())

## 💙 Reproduce una frase de ánimo aleatoria de July (1 al 8)
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
		"res://Audios/Sonidos/" + nombre_archivo + ".wav",
		"res://Audios/Sonidos/" + nombre_archivo + ".mp3"
	]
	
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

## Método global para enviar cualquier texto dinámico a la API (se queda igual)
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
