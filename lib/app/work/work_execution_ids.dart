part of 'open_works.dart';

/// 열기 한 번의 실행 수명 ID다. 외부 생성/직렬화·값 동등성·재사용을 제공하지 않는다.
final class OpenedWorkId {
  OpenedWorkId._();
}

/// 도안 변경 채택 대기 한 건의 불투명 핸들이다. 제작 검토/영구 이력 ID가 아니다.
final class GeometryChangeConfirmationId {
  GeometryChangeConfirmationId._();
}
