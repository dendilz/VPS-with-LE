resource "local_file" "AnsibleInventory" {
  content = templatefile("inventory.tmpl",
  {
   domain_name = aws_route53_record.s53_record.*.name,
  }
  )
  filename = "inventory"
}
