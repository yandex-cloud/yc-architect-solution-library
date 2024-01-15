#INITIALIZATION

variable "sauth" {
    type = string
}

variable "s3key" {
    type = string
}

variable "s3secret" {
    type = string
}

variable "zones" {
    type = map
    default ={
        "A" = "ru-central1-a"
        "B" = "ru-central1-b"
        "C" = "ru-central1_c"
    }
}

variable "folder" {
    default = ""
}

variable "cloud" {
    default = ""
}

