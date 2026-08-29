# res://Scripts_gd/PanelMaestro.gd
extends Control

# Referencias UI - Rutas exactas corregidas
@onready var selector_estudiantes: OptionButton = $VBoxPrincipal/BarraFiltros/SelectorEstudiante
@onready var selector_categoria: OptionButton = $VBoxPrincipal/BarraFiltros/SelectorCategoria
@onready var btn_actualizar: Button = $VBoxPrincipal/BarraFiltros/BtnActualizar
@onready var btn_salir: Button = $VBoxPrincipal/BarraSuperior/BtnSalir
@onready var label_maestro: Label = $VBoxPrincipal/BarraSuperior/LabelMaestro

# KPIs
@onready var kpi_total: Label = $VBoxPrincipal/ContenedorKPIs/TarjetaTotal/VBox/Valor
@onready var kpi_precision: Label = $VBoxPrincipal/ContenedorKPIs/TarjetaPrecision/VBox/Valor
@onready var kpi_tiempo: Label = $VBoxPrincipal/ContenedorKPIs/TarjetaTiempo/VBox/Valor
@onready var kpi_enfoque: Label = $VBoxPrincipal/ContenedorKPIs/TarjetaEnfoque/VBox/Valor

# Gráfico y Tabla
@onready var lienzo_grafico: Control = $VBoxPrincipal/ContenedorCuerpo/PanelGrafico/VBox/LienzoGrafico
@onready var contenedor_filas_tabla: VBoxContainer = $VBoxPrincipal/ContenedorCuerpo/PanelHistorial/VBox/Scroll/VBoxFilas
@onready var label_estado_tabla: Label = $VBoxPrincipal/ContenedorCuerpo/PanelHistorial/LabelEstado

# Diagnóstico
@onready var lbl_diag_titulo: Label = $VBoxPrincipal/PanelDiagnostico/VBox/HBoxTit/LabelTitulo
@onready var lbl_diag_desc: Label = $VBoxPrincipal/PanelDiagnostico/VBox/LabelDiagnostico
@onready var lbl_diag_recom: Label = $VBoxPrincipal/PanelDiagnostico/VBox/LabelRecomendacion

# Datos en memoria
var lista_estudiantes: Array = []
var historial_completo: Array = []
var datos_filtrados: Array = []
var stats_categorias: Dictionary = {
	"suma": {"aciertos": 0, "fallas": 0, "tiempos": [], "tiempo_prom": 0.0, "pct": 0.0},
	"resta": {"aciertos": 0, "fallas": 0, "tiempos": [], "tiempo_prom": 0.0, "pct": 0.0},
	"multiplicacion": {"aciertos": 0, "fallas": 0, "tiempos": [], "tiempo_prom": 0.0, "pct": 0.0},
	"division": {"aciertos": 0, "fallas": 0, "tiempos": [], "tiempo_prom": 0.0, "pct": 0.0}
}

var ArbolDecision = preload("res://Scripts_gd/Globales/ArbolDecisionMaestro.gd").new()

func _ready():
	# Configurar información de la sesión
	if label_maestro:
		var nombre_doc = DatosUsuario.nombre_usuario if DatosUsuario.nombre_usuario != "" else "Docente"
		label_maestro.text = "Docente: %s" % nombre_doc
		
	# Conexión de señales de filtros
	if selector_estudiantes:
		selector_estudiantes.item_selected.connect(_on_estudiante_seleccionado)
	if selector_categoria:
		selector_categoria.item_selected.connect(_on_filtro_categoria_seleccionado)
	if btn_actualizar:
		btn_actualizar.pressed.connect(_cargar_datos)
	if btn_salir:
		btn_salir.pressed.connect(_on_btn_salir_pressed)
		
	# Conectar el dibujo del gráfico
	if lienzo_grafico:
		lienzo_grafico.draw.connect(_dibujar_grafico_desempeno)
		
	# Cargar datos iniciales
	_cargar_estudiantes()

func _on_btn_salir_pressed():
	DatosUsuario.cerrar_sesion()
	NavegacionGlobal.cambiar_escena_con_carga("res://Escenas/Menu.tscn")

func _cargar_estudiantes():
	if selector_estudiantes:
		selector_estudiantes.clear()
		selector_estudiantes.add_item("Todos los Estudiantes (Aula Completa)", 0)
		selector_estudiantes.set_item_metadata(0, 0)
		
	ConexionSupabase.obtener_lista_estudiantes(func(estudiantes: Array):
		lista_estudiantes = estudiantes
		var idx = 1
		for est in lista_estudiantes:
			var id_est = int(est.get("id", 0))
			var nom_est = str(est.get("usuario", "Estudiante"))
			selector_estudiantes.add_item("%s (ID: %d)" % [nom_est, id_est], idx)
			selector_estudiantes.set_item_metadata(idx, id_est)
			idx += 1
			
		_cargar_datos()
	)

func _on_estudiante_seleccionado(_idx: int):
	_cargar_datos()

func _on_filtro_categoria_seleccionado(_idx: int):
	_procesar_y_actualizar_ui()

func _cargar_datos():
	if label_estado_tabla:
		label_estado_tabla.text = "Cargando historial de respuestas de Supabase..."
		label_estado_tabla.visible = true
		
	var id_estudiante_sel = 0
	if selector_estudiantes and selector_estudiantes.selected >= 0:
		id_estudiante_sel = selector_estudiantes.get_selected_metadata()
		
	ConexionSupabase.obtener_historial_respuestas(id_estudiante_sel, func(historial: Array):
		historial_completo = historial
		_procesar_y_actualizar_ui()
	)

func _procesar_y_actualizar_ui():
	# 1. Reiniciar acumuladores
	for cat in stats_categorias.keys():
		stats_categorias[cat] = {
			"aciertos": 0, 
			"fallas": 0, 
			"tiempos": [], 
			"tiempo_prom": 0.0, 
			"pct": 0.0
		}
		
	var cat_filtro = "todas"
	if selector_categoria and selector_categoria.selected > 0:
		match selector_categoria.selected:
			1: cat_filtro = "suma"
			2: cat_filtro = "resta"
			3: cat_filtro = "multiplicacion"
			4: cat_filtro = "division"
			
	datos_filtrados.clear()
	var total_preguntas_global = 0
	var total_aciertos_global = 0
	var total_fallas_global = 0
	var suma_tiempos_global = 0.0
	
	for reg in historial_completo:
		var cat = str(reg.get("categoria", "matematicas")).to_lower().strip_edges()
		var es_corr = bool(reg.get("es_correcta", false))
		var tiempo = float(reg.get("tiempo_tardado", 0.0))
		
		# Normalizar categoría
		if "suma" in cat or "+" in cat: cat = "suma"
		elif "resta" in cat or "-" in cat: cat = "resta"
		elif "multi" in cat or "x" in cat or "*" in cat: cat = "multiplicacion"
		elif "div" in cat or "/" in cat: cat = "division"
		else: cat = "suma" # Fallback
		
		if stats_categorias.has(cat):
			if es_corr:
				stats_categorias[cat]["aciertos"] += 1
			else:
				stats_categorias[cat]["fallas"] += 1
			stats_categorias[cat]["tiempos"].append(tiempo)
			
		total_preguntas_global += 1
		if es_corr: total_aciertos_global += 1
		else: total_fallas_global += 1
		suma_tiempos_global += tiempo
		
		# Filtrar para la tabla
		if cat_filtro == "todas" or cat == cat_filtro:
			datos_filtrados.append(reg)
			
	# Calcular promedios por categoría
	for cat in stats_categorias.keys():
		var tot = stats_categorias[cat]["aciertos"] + stats_categorias[cat]["fallas"]
		if tot > 0:
			stats_categorias[cat]["pct"] = (float(stats_categorias[cat]["aciertos"]) / float(tot)) * 100.0
			var arr_t = stats_categorias[cat]["tiempos"]
			var s_t = 0.0
			for t in arr_t: s_t += t
			stats_categorias[cat]["tiempo_prom"] = s_t / float(arr_t.size())
			
	# 2. Actualizar Tarjetas KPI
	var tiempo_prom_global = (suma_tiempos_global / float(total_preguntas_global)) if total_preguntas_global > 0 else 0.0
	var pct_global = ((float(total_aciertos_global) / float(total_preguntas_global)) * 100.0) if total_preguntas_global > 0 else 0.0
	
	if kpi_total:
		kpi_total.text = "%d" % total_preguntas_global
	if kpi_precision:
		kpi_precision.text = "%.1f%%" % pct_global
		kpi_precision.modulate = Color("#10b981") if pct_global >= 70 else (Color("#fbbf24") if pct_global >= 50 else Color("#ef4444"))
	if kpi_tiempo:
		kpi_tiempo.text = "%.2f s" % tiempo_prom_global
	if kpi_enfoque:
		kpi_enfoque.text = _determinar_categoria_destacada()
		
	# 3. Actualizar Diagnóstico Pedagógico
	_actualizar_diagnostico_pedagogico(total_aciertos_global, total_fallas_global, tiempo_prom_global)
	
	# 4. Redibujar Gráfico
	if lienzo_grafico:
		lienzo_grafico.queue_redraw()
		
	# 5. Rellenar Tabla de Historial
	_actualizar_tabla_historial()

func _determinar_categoria_destacada() -> String:
	var mejor_cat = ""
	var mejor_pct = -1.0
	var peor_cat = ""
	var peor_pct = 999.0
	
	for cat in stats_categorias.keys():
		var tot = stats_categorias[cat]["aciertos"] + stats_categorias[cat]["fallas"]
		if tot >= 2:
			var pct = stats_categorias[cat]["pct"]
			if pct > mejor_pct:
				mejor_pct = pct
				mejor_cat = cat
			if pct < peor_pct:
				peor_pct = pct
				peor_cat = cat
				
	if peor_cat != "" and peor_pct < 60.0:
		return "Reforzar %s (%.0f%%)" % [peor_cat.capitalize(), peor_pct]
	elif mejor_cat != "":
		return "Destacado: %s (%.0f%%)" % [mejor_cat.capitalize(), mejor_pct]
	return "En evaluacion"

func _actualizar_diagnostico_pedagogico(aciertos: int, fallas: int, tiempo_prom: float):
	var diag = ArbolDecision.procesar_diagnostico_global(aciertos, fallas, tiempo_prom, stats_categorias)
	if lbl_diag_titulo: lbl_diag_titulo.text = diag.get("titulo", "Diagnostico Pedagogico")
	if lbl_diag_desc: lbl_diag_desc.text = diag.get("diagnostico", "")
	if lbl_diag_recom: lbl_diag_recom.text = "Consejo Docente: " + diag.get("recomendacion", "")

# =====================================================================
# RENDERIZADO DEL GRAFICO VECTORIAL DE DESEMPENO
# =====================================================================
func _dibujar_grafico_desempeno():
	if not lienzo_grafico: return
	var g_size = lienzo_grafico.size
	if g_size.x < 50 or g_size.y < 50: return
	
	# Area de dibujo con margenes para ejes
	var margin_left = 55.0
	var margin_right = 55.0
	var margin_top = 35.0
	var margin_bottom = 45.0
	
	var chart_w = g_size.x - margin_left - margin_right
	var chart_h = g_size.y - margin_top - margin_bottom
	var chart_bottom = g_size.y - margin_bottom
	
	# 1. Fondo y Lineas de Cuadricula Horizontal
	var font = ThemeDB.fallback_font
	var font_size = 12
	
	for i in range(5):
		var pct_val = i * 25 # 0%, 25%, 50%, 75%, 100%
		var y = chart_bottom - (chart_h * (pct_val / 100.0))
		# Linea tenue
		lienzo_grafico.draw_line(Vector2(margin_left, y), Vector2(g_size.x - margin_right, y), Color(1, 1, 1, 0.08), 1.0)
		# Texto Eje Izquierdo (% Precision)
		lienzo_grafico.draw_string(font, Vector2(10, y + 4), "%d%%" % pct_val, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size, Color("#94a3b8"))
		
	# Eje Derecho: Escala de Tiempos (0s, 5s, 10s, 15s)
	for i in range(4):
		var seg_val = i * 5.0
		var y = chart_bottom - (chart_h * (seg_val / 15.0))
		lienzo_grafico.draw_string(font, Vector2(g_size.x - margin_right + 8, y + 4), "%.0fs" % seg_val, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#38bdf8"))
		
	# 2. Dibujar Columnas y Curva por Categoria
	var categorias = ["suma", "resta", "multiplicacion", "division"]
	var nombres_cat = ["SUMA", "RESTA", "MULTI", "DIVISION"]
	var num_cats = categorias.size()
	var slot_w = chart_w / float(num_cats)
	var bar_w = min(slot_w * 0.45, 45.0)
	
	var puntos_tiempo: PackedVector2Array = []
	
	for i in range(num_cats):
		var cat_key = categorias[i]
		var data = stats_categorias[cat_key]
		var total_cat = data["aciertos"] + data["fallas"]
		var center_x = margin_left + (i * slot_w) + (slot_w / 2.0)
		
		# A) Barras apiladas de Aciertos (Verde) y Errores (Rojo)
		if total_cat > 0:
			var pct_aciertos = data["pct"]
			var h_aciertos = chart_h * (pct_aciertos / 100.0)
			var h_fallas = chart_h * ((100.0 - pct_aciertos) / 100.0)
			
			# Barra Fallas (Rojo / fondo superior)
			if h_fallas > 0:
				var rect_err = Rect2(center_x - (bar_w / 2.0), chart_bottom - chart_h, bar_w, h_fallas)
				lienzo_grafico.draw_rect(rect_err, Color("#ef4444"), true)
				
			# Barra Aciertos (Verde / base)
			if h_aciertos > 0:
				var rect_ok = Rect2(center_x - (bar_w / 2.0), chart_bottom - h_aciertos, bar_w, h_aciertos)
				lienzo_grafico.draw_rect(rect_ok, Color("#10b981"), true)
				
			# Borde de la barra
			var rect_total = Rect2(center_x - (bar_w / 2.0), chart_bottom - chart_h, bar_w, chart_h)
			lienzo_grafico.draw_rect(rect_total, Color(1, 1, 1, 0.2), false, 2.0)
			
			# Porcentaje encima de la barra
			lienzo_grafico.draw_string(font, Vector2(center_x - 24, chart_bottom - chart_h - 8), "%.0f%%" % pct_aciertos, HORIZONTAL_ALIGNMENT_CENTER, 48, font_size, Color("#fde047"))
		else:
			# Barra vacia sin datos
			var rect_vacio = Rect2(center_x - (bar_w / 2.0), chart_bottom - (chart_h * 0.1), bar_w, chart_h * 0.1)
			lienzo_grafico.draw_rect(rect_vacio, Color(0.2, 0.25, 0.35, 0.4), true)
			lienzo_grafico.draw_string(font, Vector2(center_x - 24, chart_bottom - 15), "S/D", HORIZONTAL_ALIGNMENT_CENTER, 48, font_size, Color("#64748b"))
			
		# B) Punto de Tiempo Promedio para la curva
		var t_prom = clampf(data["tiempo_prom"], 0.0, 15.0)
		var y_tiempo = chart_bottom - (chart_h * (t_prom / 15.0))
		puntos_tiempo.append(Vector2(center_x, y_tiempo))
		
		# Etiqueta de Categoria debajo
		lienzo_grafico.draw_string(font, Vector2(center_x - 30, chart_bottom + 22), nombres_cat[i], HORIZONTAL_ALIGNMENT_CENTER, 60, font_size + 1, Color.WHITE)
		
	# 3. Dibujar Linea y Puntos de Tiempos de Respuesta
	if puntos_tiempo.size() > 1:
		for i in range(puntos_tiempo.size() - 1):
			lienzo_grafico.draw_line(puntos_tiempo[i], puntos_tiempo[i+1], Color("#38bdf8"), 3.0, true)
			
	for i in range(puntos_tiempo.size()):
		var p = puntos_tiempo[i]
		var data = stats_categorias[categorias[i]]
		# Halo y punto cian
		lienzo_grafico.draw_circle(p, 6.0, Color("#38bdf8"))
		lienzo_grafico.draw_circle(p, 3.0, Color.WHITE)
		if data["aciertos"] + data["fallas"] > 0:
			lienzo_grafico.draw_string(font, Vector2(p.x + 8, p.y - 6), "%.1fs" % data["tiempo_prom"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#38bdf8"))

# =====================================================================
# TABLA DETALLADA DE HISTORIAL DE RESPUESTAS
# =====================================================================
func _actualizar_tabla_historial():
	if not contenedor_filas_tabla: return
	
	# Limpiar filas previas
	for h in contenedor_filas_tabla.get_children():
		h.queue_free()
		
	if datos_filtrados.is_empty():
		if label_estado_tabla:
			label_estado_tabla.text = "No se encontraron registros de respuestas con los filtros seleccionados."
			label_estado_tabla.visible = true
		return
		
	if label_estado_tabla:
		label_estado_tabla.visible = false
		
	for reg in datos_filtrados:
		var panel_fila = PanelContainer.new()
		panel_fila.custom_minimum_size = Vector2(0, 38)
		
		var st_f = StyleBoxFlat.new()
		st_f.bg_color = Color("#0f172a")
		st_f.border_color = Color(1, 1, 1, 0.06)
		st_f.set_border_width_all(1)
		st_f.set_corner_radius_all(8)
		panel_fila.add_theme_stylebox_override("panel", st_f)
		
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 12)
		panel_fila.add_child(hbox)
		
		# Categoria
		var cat_name = str(reg.get("categoria", "Matematicas")).capitalize()
		var lbl_cat = Label.new()
		lbl_cat.text = "[%s]" % cat_name
		lbl_cat.custom_minimum_size = Vector2(100, 0)
		lbl_cat.add_theme_font_size_override("font_size", 13)
		lbl_cat.add_theme_color_override("font_color", Color("#38bdf8"))
		hbox.add_child(lbl_cat)
		
		# Resultado Correcto / Error
		var es_corr = bool(reg.get("es_correcta", false))
		var lbl_res = Label.new()
		lbl_res.text = "Correcta" if es_corr else "Incorrecta"
		lbl_res.custom_minimum_size = Vector2(100, 0)
		lbl_res.add_theme_font_size_override("font_size", 13)
		lbl_res.add_theme_color_override("font_color", Color("#10b981") if es_corr else Color("#ef4444"))
		hbox.add_child(lbl_res)
		
		# Tiempo tardado
		var tiempo = float(reg.get("tiempo_tardado", 0.0))
		var lbl_t = Label.new()
		lbl_t.text = "%.2f seg" % tiempo
		lbl_t.custom_minimum_size = Vector2(85, 0)
		lbl_t.add_theme_font_size_override("font_size", 13)
		lbl_t.add_theme_color_override("font_color", Color("#fbbf24"))
		hbox.add_child(lbl_t)
		
		# Fecha / Timestamp
		var fecha_raw = str(reg.get("created_at", ""))
		var fecha_corta = fecha_raw.substr(0, 10) + " " + fecha_raw.substr(11, 8) if fecha_raw.length() >= 19 else fecha_raw
		var lbl_fecha = Label.new()
		lbl_fecha.text = fecha_corta
		lbl_fecha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_fecha.add_theme_font_size_override("font_size", 12)
		lbl_fecha.add_theme_color_override("font_color", Color("#64748b"))
		hbox.add_child(lbl_fecha)
		
		contenedor_filas_tabla.add_child(panel_fila)
