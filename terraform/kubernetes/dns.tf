resource "alicloud_alidns_domain" "default" {
  domain_name = "szp15.com"
  lifecycle {
    prevent_destroy = true
  }
}

data "alicloud_ram_policy_document" "dns_management" {
  version = "1"
  statement {
    effect = "Allow"
    action = [
      "alidns:AddDomainRecord",
      "alidns:DeleteDomainRecord",
      "alidns:UpdateDomainRecord",
      "alidns:DescribeDomainRecords",
      "alidns:DescribeDomains",
      "pvtz:AddZoneRecord",
      "pvtz:DeleteZoneRecord",
      "pvtz:UpdateZoneRecord",
      "pvtz:DescribeZoneRecords",
      "pvtz:DescribeZones",
      "pvtz:DescribeZoneInfo",
    ]
    resource = ["*"]
  }
}

resource "alicloud_ram_policy" "dns_management" {
  policy_name     = "dns-management"
  policy_document = data.alicloud_ram_policy_document.dns_management.document
  description     = "DNS Management Policy"
  rotate_strategy = "DeleteOldestNonDefaultVersionWhenLimitExceeded"
}

data "alicloud_ram_policy_document" "dns_management_assume_role" {
  version = "1"
  statement {
    effect = "Allow"
    action = ["sts:AssumeRole"]
    principal {
      entity      = "Service"
      identifiers = ["ecs.aliyuncs.com"]
    }
  }
}

# TODO: currently this RAM role is manually attached to the ECS instance
resource "alicloud_ram_role" "dns_management" {
  name        = "dns-management"
  document    = data.alicloud_ram_policy_document.dns_management_assume_role.document
  description = "DNS Management Role"
}

resource "alicloud_ram_role_policy_attachment" "dns_management" {
  policy_name = alicloud_ram_policy.dns_management.policy_name
  policy_type = alicloud_ram_policy.dns_management.type
  role_name   = alicloud_ram_role.dns_management.name
}
