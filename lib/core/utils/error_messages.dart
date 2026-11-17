import '../error/app_exception.dart';

String errorTitle(AppErrorType? type) {
  switch (type) {
    case AppErrorType.rateLimited:
      return 'Слишком много запросов';
    case AppErrorType.network:
      return 'Нет связи с Deadlock API';
    case AppErrorType.unknown:
    case null:
      return 'Не удалось загрузить данные';
  }
}

String errorText(AppErrorType? type) {
  switch (type) {
    case AppErrorType.rateLimited:
      return 'API временно ограничил запросы. Подожди минуту и попробуй снова.';
    case AppErrorType.network:
      return 'Проверь интернет-соединение и повтори запрос.';
    case AppErrorType.unknown:
    case null:
      return 'Сервис вернул неожиданный ответ. Попробуй обновить экран.';
  }
}
