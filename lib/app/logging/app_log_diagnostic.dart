/// 처리 경계가 로그 공개를 승인한 최소 진단이다. 업무 예외/상태의 자동 직렬화가 아니다.
///
/// code·fieldPath·operation은 개발자가 정의한 메타데이터만 전달한다.
/// 원문, ID를 끼워 넣은 경로, 외부 메시지·실제 입력값은 전달하지 않는다.
/// 이 타입 자체가 문자열에 업무 정보가 없는지 판별하지는 않는다.
final class AppLogDiagnostic {
  /// 알려진 오류를 해석하는 경계에서 필요한 필드만 선택한다.
  /// 타입 차이는 [type]의 기대/실제 타입 이름으로 함께 전달한다.
  const AppLogDiagnostic({
    required this.code,
    this.fieldPath,
    this.type,
    this.operation,
  });

  /// 의미를 아는 오류의 기계 판별 코드다. error.toString에서 추출하지 않는다.
  final String code;

  /// 모델/JSON의 필드와 0 기반 목록 인덱스다. ID나 로컬 파일 경로가 아니다.
  final String? fieldPath;

  /// 실제 입력값을 담지 않는 기대/실제 타입 쌍이다.
  final AppLogTypeDiagnostic? type;

  /// 실패 연산의 개발자용 이름이다. 외부 오류 메시지와 구분한다.
  final String? operation;

  /// 승인된 필드만 출력한다. 예외 원문·객체·상태로 확장하지 않는다.
  Map<String, Object?> toJson() => {
    'code': code,
    if (fieldPath != null) 'fieldPath': fieldPath,
    if (type case final type?) ...{
      'expectedType': type.expectedType,
      'actualType': type.actualType,
    },
    if (operation != null) 'operation': operation,
  };
}

/// 타입 진단의 두 이름을 하나로 전달한다. 실제 값/문자열 덤프를 받지 않는다.
final class AppLogTypeDiagnostic {
  /// 처리 경계가 아는 기대 타입과 실제 타입 이름이다.
  const AppLogTypeDiagnostic({
    required this.expectedType,
    required this.actualType,
  });

  /// 요구한 JSON/Dart 타입 이름이다.
  final String expectedType;

  /// 실제 타입 이름이다. null은 Null이며 원래 입력 내용은 담지 않는다.
  final String actualType;
}
