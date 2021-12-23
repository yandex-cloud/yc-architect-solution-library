name   = "tf-sg"
vpc_id = "enp5v4es0f4vgdbou270"
self   = true
ingress_rules_with_cidrs = [
  {
    description    = "ssh"
    port           = 22
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  },
  {
    description    = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  },
  {
    protocol       = "TCP"
    description    = "NLB health check"
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
    from_port      = 0
    to_port        = 65535
  },
]
ingress_rules_with_sg_ids = [
  {
    protocol          = "ANY"
    description       = "Communication with web SG"
    security_group_id = "enpbr4hmdn785jdqdiea"
  },
]
egress_rules = [
  {
    protocol       = "ANY"
    description    = "To the internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
  },
]
