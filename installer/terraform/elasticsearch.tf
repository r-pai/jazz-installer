resource "aws_elasticsearch_domain" "elasticsearch_domain" {
  domain_name           = "${var.envPrefix}"
  elasticsearch_version = "5.1"
  cluster_config {
    instance_type = "m3.medium.elasticsearch"
    instance_count =2
    dedicated_master_enabled = false
    zone_awareness_enabled= false
  }
  ebs_options{
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 10
  }

  tags = "${merge(var.additional_tags, local.common_tags, map(
          "Domain", "${var.envPrefix}_elasticsearch_domain",
          ))}"

  access_policies = <<POLICIES

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": {
                "AWS": "*"
                },
            "Effect": "Allow",
            "Condition": {
                "IpAddress": {"aws:SourceIp": "${var.dockerizedJenkins == 1 ? format("%s%s", join(" ", aws_eip.elasticip.*.public_ip), "/32" ) : "0.0.0.0/0" }"}
            }
        }
    ]
}
POLICIES

}

#This script is designed to fail if the user did not specify a valid, preexisting sercurity group,
#we will just create one.
#TODO Not a huge fan of `on_failure continue`, we need a smarter way to decide if this needs to be run or not
resource "null_resource" "updateSecurityGroup" {
   provisioner "local-exec" {
    command    = "aws ec2 authorize-security-group-ingress --group-id ${lookup(var.jenkinsservermap, "jenkins_security_group")} --protocol tcp --port 443 --source-group ${lookup(var.jenkinsservermap, "jenkins_security_group")} --region ${var.region}"
    on_failure = "continue"
  }
}
