variable user_map {
  type = map(object({
    admin = bool
    groups = list(string)
  }))
}
