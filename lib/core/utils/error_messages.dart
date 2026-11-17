import '../error/app_exception.dart';

String errorTitle(AppErrorType? type) {
  switch (type) {
    case AppErrorType.rateLimited:
      return 'Слишком много запросов';
    case AppErrorType.network:
      return 'Нет связи с Deadlock API';
    case AppErrorType.timeout:
      return 'Deadlock API не ответил вовремя';
    case AppErrorType.server:
      return 'Ошибка на стороне Deadlock API';
    case AppErrorType.notFound:
      return 'Данные не найдены';
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
    case AppErrorType.timeout:
      return 'Сервер долго не отвечает. Повтори запрос чуть позже.';
    case AppErrorType.server:
      return 'Сервис временно недоступен. Попробуй обновить экран позже.';
    case AppErrorType.notFound:
      return 'По этому запросу ничего не найдено.';
    case AppErrorType.unknown:
    case null:
      return 'Сервис вернул неожиданный ответ. Попробуй обновить экран.';
  }
}
