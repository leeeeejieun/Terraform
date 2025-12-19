output "upper_names" {
  value = [for name in var.user_names : upper(name) if length(name) < 4]
}

output "bios" {
  # ex) neo is the hero
  value = [for name, role in var.hero_thousand_faces : "${name} is the ${role}"]
}

# output "all_ids" {
#   value = aws_iam_user.createuser[*]
# }
