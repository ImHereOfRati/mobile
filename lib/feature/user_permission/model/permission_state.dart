enum PermissionState {
  grantedAlways, // 항상 허용됨
  grantedWhenInUse, // 앱 사용 중에만 허용됨
  denied, // 거부됨
  permanentlyDenied, // 영구적으로 거부됨
  restricted, // 제한됨
}
