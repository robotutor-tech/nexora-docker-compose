package authz

default allow = false

allow if has_entitlement

has_entitlement if {
  some e
  ent := input.entitlements[e]

  input.resource.type == ent.resource.type
  input.resource.id == ent.resource.id
  input.premisesId == ent.premisesId
  action_allowed(input.resource.action, ent.resource.action)
}

has_entitlement if {
  some e
  ent := input.entitlements[e]

  input.resource.type == ent.resource.type
  input.resource.id == "*"
  input.premisesId == ent.premisesId
  action_allowed(input.resource.action, ent.resource.action)
}

action_allowed(request, granted) if {
    request == granted
}

action_allowed(request, granted) if {
    request == "LIST"
    granted == "READ"
}