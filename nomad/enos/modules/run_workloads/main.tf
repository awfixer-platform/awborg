# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

terraform {
  required_providers {
    enos = {
      source = "hashicorp-forge/enos"
    }
  }
}

locals {
  nomad_env = {
    NOMAD_ADDR        = var.nomad_addr
    NOMAD_CACERT      = var.ca_file
    NOMAD_CLIENT_CERT = var.cert_file
    NOMAD_CLIENT_KEY  = var.key_file
    NOMAD_TOKEN       = var.nomad_token
  }

  consul_env = {
    CONSUL_HTTP_TOKEN = var.consul_token
    CONSUL_CACERT     = var.ca_file
    CONSUL_HTTP_ADDR  = var.consul_addr
  }

  vault_env = {
    VAULT_TOKEN = var.vault_token
    VAULT_PATH  = var.vault_mount_path
    VAULT_ADDR  = var.vault_addr
  }

  system_job_count     = length({ for k, v in var.workloads : k => v if v.type == "system" })
  service_batch_allocs = sum([for wl in var.workloads : wl.alloc_count])
}

resource "enos_local_exec" "wait_for_nomad_api" {
  environment = local.nomad_env

  scripts = [abspath("${path.module}/scripts/wait_for_nomad_api.sh")]
}

resource "enos_local_exec" "get_nodes" {
  depends_on  = [enos_local_exec.wait_for_nomad_api]
  environment = local.nomad_env

  inline = ["nomad node status -json | jq '[.[] | select(.SchedulingEligibility == \"eligible\" and .Status == \"ready\")] | length'"]
}

resource "enos_local_exec" "get_jobs" {
  depends_on  = [enos_local_exec.wait_for_nomad_api]
  environment = local.nomad_env

  inline = ["nomad job status| awk '$4 == \"running\" {count++} END {print count+0}'"]
}

resource "enos_local_exec" "get_allocs" {
  depends_on  = [enos_local_exec.wait_for_nomad_api]
  environment = local.nomad_env

  inline = ["nomad alloc status -json | jq '[.[] | select(.ClientStatus == \"running\")] | length'"]
}

resource "local_file" "vault_workload" {
  filename = "${path.module}/jobs/vault-secrets.nomad.hcl"
  content = templatefile("${path.module}/templates/vault-secrets.nomad.hcl.tpl", {
    secret_path = "${var.vault_mount_path}/default/get-secret"
  })
}

resource "enos_local_exec" "workloads" {
  depends_on = [
    enos_local_exec.get_jobs,
    enos_local_exec.get_allocs,
    local_file.vault_workload
  ]
  for_each = var.workloads

  environment = merge(
    local.nomad_env,
    local.vault_env,
    local.consul_env,
  )

  inline = [
    each.value.pre_script != null ? abspath("${path.module}/${each.value.pre_script}") : "echo ok",
    "nomad job run -var alloc_count=${each.value.alloc_count} ${path.module}/${each.value.job_spec}",
    each.value.post_script != null ? abspath("${path.module}/${each.value.post_script}") : "echo ok"
  ]
}
