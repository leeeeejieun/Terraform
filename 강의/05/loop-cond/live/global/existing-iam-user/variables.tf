##### for expression - list input #####
variable "user_names" {
  type = list(string)
  default = ["red", "blue", "green"]
}

##### for expression - map input #####
variable "hero_thousand_faces" {
  description = "map"
  type        = map(string)
  default     = {
    neo      = "hero"              
    trinity  = "love interest"   
    morpheus = "mentor"
  }
}