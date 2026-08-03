import 'idioma.dart';

/// Nombres de días y meses traducidos, para no repetir listas hardcodeadas
/// en cada pantalla que dibuja un calendario.
class CalendarioI18n {
  /// Lunes..Domingo, abreviado a 3 letras.
  static List<String> diasAbrev3(Idioma idioma) => switch (idioma) {
        Idioma.es => const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'],
        Idioma.en => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        Idioma.ru => const [
            'Пн',
            'Вт',
            'Ср',
            'Чт',
            'Пт',
            'Сб',
            'Вс',
          ],
        Idioma.zh => const [
            '周一',
            '周二',
            '周三',
            '周四',
            '周五',
            '周六',
            '周日',
          ],
      };

  /// Lunes..Domingo, abreviado a 1 letra (grillas compactas).
  static List<String> diasAbrev1(Idioma idioma) => switch (idioma) {
        Idioma.es => const ['L', 'M', 'X', 'J', 'V', 'S', 'D'],
        Idioma.en => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
        Idioma.ru => const ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'],
        Idioma.zh => const ['一', '二', '三', '四', '五', '六', '日'],
      };

  /// Lunes..Domingo, completo.
  static List<String> diasCompletos(Idioma idioma) => switch (idioma) {
        Idioma.es => const [
            'Lunes',
            'Martes',
            'Miércoles',
            'Jueves',
            'Viernes',
            'Sábado',
            'Domingo',
          ],
        Idioma.en => const [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ],
        Idioma.ru => const [
            'Понедельник',
            'Вторник',
            'Среда',
            'Четверг',
            'Пятница',
            'Суббота',
            'Воскресенье',
          ],
        Idioma.zh => const [
            '星期一',
            '星期二',
            '星期三',
            '星期四',
            '星期五',
            '星期六',
            '星期日',
          ],
      };

  /// Enero..Diciembre, abreviado a 3 letras.
  static List<String> mesesAbrev(Idioma idioma) => switch (idioma) {
        Idioma.es => const [
            'Ene',
            'Feb',
            'Mar',
            'Abr',
            'May',
            'Jun',
            'Jul',
            'Ago',
            'Sep',
            'Oct',
            'Nov',
            'Dic',
          ],
        Idioma.en => const [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ],
        Idioma.ru => const [
            'Янв',
            'Фев',
            'Мар',
            'Апр',
            'Май',
            'Июн',
            'Июл',
            'Авг',
            'Сен',
            'Окт',
            'Ноя',
            'Дек',
          ],
        Idioma.zh => const [
            '1月',
            '2月',
            '3月',
            '4月',
            '5月',
            '6月',
            '7月',
            '8月',
            '9月',
            '10月',
            '11月',
            '12月',
          ],
      };

  /// Enero..Diciembre, completo (para "hoy es 3 de enero" en minúscula en es).
  static List<String> mesesCompletos(Idioma idioma) => switch (idioma) {
        Idioma.es => const [
            'enero',
            'febrero',
            'marzo',
            'abril',
            'mayo',
            'junio',
            'julio',
            'agosto',
            'septiembre',
            'octubre',
            'noviembre',
            'diciembre',
          ],
        Idioma.en => const [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ],
        Idioma.ru => const [
            'января',
            'февраля',
            'марта',
            'апреля',
            'мая',
            'июня',
            'июля',
            'августа',
            'сентября',
            'октября',
            'ноября',
            'декабря',
          ],
        Idioma.zh => const [
            '1月',
            '2月',
            '3月',
            '4月',
            '5月',
            '6月',
            '7月',
            '8月',
            '9月',
            '10月',
            '11月',
            '12月',
          ],
      };
}
