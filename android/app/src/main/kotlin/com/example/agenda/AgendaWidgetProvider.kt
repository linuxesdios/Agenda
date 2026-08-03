package com.example.agenda

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Typeface
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Widget de pantalla de inicio de Android para la Agenda.
///
/// Extiende HomeWidgetProvider (del paquete home_widget), que ya
/// entrega los datos guardados por Flutter en `widgetData`.
///
/// Android llama a onUpdate() cuando:
///  - Se añade el widget a la pantalla
///  - Pasa el intervalo de refresco (agenda_widget_info.xml, 30 min)
///  - Flutter llama a HomeWidget.updateWidget()
class AgendaWidgetProvider : HomeWidgetProvider() {

    /// Una sección de contenido con su título y color de cabecera.
    private data class Seccion(val titulo: String, val contenido: String, val color: Int)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.agenda_widget)

            // ── Leer datos que Flutter guardó (servicio_widget.dart) ──
            val titulo = widgetData.getString("titulo_widget", "Agenda") ?: "Agenda"
            val fecha = widgetData.getString("fecha_widget", "") ?: ""
            val contador = widgetData.getString("contador_widget", "0")?.toIntOrNull() ?: 0
            val citas = widgetData.getString("citas_widget", "") ?: ""
            val criticas = widgetData.getString("criticas_widget", "") ?: ""
            val hoy = widgetData.getString("hoy_widget", "") ?: ""
            val listas = widgetData.getString("listas_widget", "") ?: ""

            // Títulos de sección, ya traducidos por Flutter (servicio_widget.dart).
            // Los defaults en español son solo por si el widget se coloca antes
            // de que la app llegue a escribir datos por primera vez.
            val tituloCriticas = widgetData.getString("titulo_criticas_widget", "CRÍTICAS") ?: "CRÍTICAS"
            val tituloCitas = widgetData.getString("titulo_citas_widget", "CITAS") ?: "CITAS"
            val tituloHoy = widgetData.getString("titulo_hoy_widget", "HOY") ?: "HOY"
            val tituloListas = widgetData.getString("titulo_listas_widget", "LISTAS") ?: "LISTAS"
            val sinPendientes = widgetData.getString("sin_pendientes_widget", "Sin tareas ni citas 🎉")
                ?: "Sin tareas ni citas 🎉"

            // ── Cabecera: título + fecha + píldora de pendientes ──
            views.setTextViewText(R.id.widget_titulo, titulo)
            views.setTextViewText(R.id.widget_fecha, fecha)
            if (contador > 0) {
                views.setTextViewText(R.id.widget_contador, contador.toString())
                views.setViewVisibility(R.id.widget_contador, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_contador, View.GONE)
            }

            // ── Contenido: una sección por categoría activa, con su propio color ──
            val secciones = listOf(
                Seccion(tituloCriticas, criticas, 0xFFE53935.toInt()),
                Seccion(tituloCitas, citas, 0xFF00897B.toInt()),
                Seccion(tituloHoy, hoy, 0xFF5E7CE2.toInt()),
                Seccion(tituloListas, listas, 0xFF7C4DFF.toInt()),
            ).filter { it.contenido.isNotBlank() }

            val texto = if (secciones.isEmpty()) {
                SpannableStringBuilder(sinPendientes)
            } else {
                val builder = SpannableStringBuilder()
                secciones.forEachIndexed { i, seccion ->
                    if (i > 0) builder.append("\n\n")
                    val inicio = builder.length
                    builder.append(seccion.titulo)
                    builder.setSpan(
                        StyleSpan(Typeface.BOLD),
                        inicio, builder.length,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                    builder.setSpan(
                        ForegroundColorSpan(seccion.color),
                        inicio, builder.length,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                    builder.append("\n")
                    builder.append(seccion.contenido)
                }
                builder
            }
            views.setTextViewText(R.id.widget_contenido, texto)

            // ── Al tocar el widget, abrir la app ──
            val abrirApp = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_root, abrirApp)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
