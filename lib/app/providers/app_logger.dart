import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_logger.g.dart';

/// 앱 실행 경계의 로거를 제공한다. 업무 패키지의 전역 의존성으로 사용하지 않는다.
@Riverpod(keepAlive: true)
Logger appLogger(Ref ref) => Logger('r_edit.app');
