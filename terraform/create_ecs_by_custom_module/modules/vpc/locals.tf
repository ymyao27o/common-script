locals {
  # Split the input IP address into a list of parts
  ip_parts = split(".", var.ip_address)

  # Determine the number of parts in the input IP address
  ip_length = length(local.ip_parts)

  # Pad the IP address to ensure it has four parts
  padded_ip_parts = [
    local.ip_length > 0 ? local.ip_parts[0] : "0",
    local.ip_length > 1 ? local.ip_parts[1] : "0",
    local.ip_length > 2 ? local.ip_parts[2] : "0",
    local.ip_length > 3 ? local.ip_parts[3] : "0",
  ]

  # 192.168.0.0/16、172.16.0.0/12、10.0.0.0/8


  # Join the parts back into a complete IP address
  complete_ip_address = join(".", slice(local.padded_ip_parts, 0, 4))
}