
terraform {
  required_providers {
    databricks = {
      source  = "databrickslabs/databricks"
      version = "0.4.9"
    }
  }
}

data "databricks_group" "admins" {
  display_name = "admins"
  provider     = databricks
}

resource "databricks_group_member" "admin_member" {
  for_each  = { for k in compact([for k, v in var.user_map : v.admin ? k : ""]) : k => var.user_map[k] }
  group_id  = data.databricks_group.admins.id
  member_id = databricks_user.user[each.key].id
}

resource "databricks_user" "user" {
  for_each         = var.user_map
  user_name        = each.key
  active           = true
  workspace_access = true
}

locals {
  usersToGroups = flatten([for key, value in var.user_map : [
    for group in value.groups : {
      group  = group
      member = key
    }
    ]
    ]
  )
  groupsList = toset(distinct([for e in local.usersToGroups : lookup(e, "group")]))
}

resource "databricks_group" "group" {
  depends_on   = [databricks_user.user]
  for_each     = local.groupsList
  display_name = title(replace(each.key, "_", " "))
}

resource "databricks_group_member" "member" {
  depends_on = [databricks_group.group]
  for_each   = { for ug in local.usersToGroups : ug.member => ug.group }
  group_id   = databricks_group.group[each.value].id
  member_id  = databricks_user.user[each.key].id
}



