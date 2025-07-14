/// Utilidad para traducir fechas de inglés a español
class DateTranslationUtil {
  /// Mapeo de meses en inglés a español
  static const Map<String, String> _monthTranslations = {
    'January': 'Enero',
    'February': 'Febrero', 
    'March': 'Marzo',
    'April': 'Abril',
    'May': 'Mayo',
    'June': 'Junio',
    'July': 'Julio',
    'August': 'Agosto',
    'September': 'Septiembre',
    'October': 'Octubre',
    'November': 'Noviembre',
    'December': 'Diciembre',
  };

  /// Mapeo de días de la semana en inglés a español
  static const Map<String, String> _dayTranslations = {
    'Monday': 'Lunes',
    'Tuesday': 'Martes',
    'Wednesday': 'Miércoles',
    'Thursday': 'Jueves',
    'Friday': 'Viernes',
    'Saturday': 'Sábado',
    'Sunday': 'Domingo',
  };

  /// Traduce una fecha formateada de inglés a español
  /// Ejemplo: "January 2025" -> "Enero 2025"
  static String translateDate(String englishDate) {
    String translatedDate = englishDate;
    
    // Traducir meses
    _monthTranslations.forEach((english, spanish) {
      translatedDate = translatedDate.replaceAll(english, spanish);
    });
    
    // Traducir días
    _dayTranslations.forEach((english, spanish) {
      translatedDate = translatedDate.replaceAll(english, spanish);
    });
    
    return translatedDate;
  }

  /// Obtiene el nombre del mes en español para un número de mes (1-12)
  static String getSpanishMonthName(int month) {
    const monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    if (month >= 1 && month <= 12) {
      return monthNames[month - 1];
    }
    return 'Mes $month';
  }

  /// Formatea una fecha en español
  /// Ejemplo: DateTime(2025, 7, 13) -> "Julio 2025"
  static String formatMonthYear(DateTime date) {
    return '${getSpanishMonthName(date.month)} ${date.year}';
  }
}
