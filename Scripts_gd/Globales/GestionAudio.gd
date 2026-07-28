# res://Scripts_gd/GestionAudio.gd
extends Node

signal audio_finalizado # 📢 NUEVA SEÑAL

# Configuración de ElevenLabs
const API_KEY : String = "sk_35961d2cccee5f5e52f5c760b9f52f95ebfe236a10cae5f3"
const VOICE_ID : String = "vAcVPeEOlCrOxhRoCXb8"  

var http_request : HTTPRequest
var audio_player : AudioStreamPlayer

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	# Opcional: Conectar cuando el audio termine por si necesitas activar algo en la interfaz
	audio_player.finished.connect(func(): audio_finalizado.emit())

## 🔊 NUEVO MÉTODO: Para reproducir frases fijas descargadas localmente
func reproducir_audio_local(nombre_archivo: String) -> void:
	# Si ya estaba sonando algo, lo detenemos
	if audio_player.playing:
		audio_player.stop()
		
	var ruta = "res://Audios/" + nombre_archivo + ".mp3"
	
	# Verificamos si el archivo realmente existe en las carpetas para evitar crasheos
	if ResourceLoader.exists(ruta):
		var stream = load(ruta)
		audio_player.stream = stream
		audio_player.play()
		print("🔊 Reproduciendo audio local: ", nombre_archivo)
	else:
		print("❌ Error: El archivo de audio local no existe en la ruta: ", ruta)

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
