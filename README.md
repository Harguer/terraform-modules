
# terraform-modules

Reusable Terraform modules for Kubernetes infrastructure and add-ons.

## Structure

- `kubernetes-cluster/` — Provisions a Kubernetes cluster (e.g., on Raspberry Pi, VMs, or cloud).
- `kubernetes-addons/` — Installs and configures add-ons like ArgoCD, cert-manager, MetalLB, Istio, and External Secrets.
- `kubernetes-addons/crds/` — Manages Kubernetes CRDs for add-ons (e.g., MetalLB IP pools, ArgoCD projects).
- `os_modules/` - Contains modules for configuring operating system services like firewalls.
- `openldap-module/` - **Restore-only:** Restores an OpenLDAP server from backup (not for general deployment; see module README).

## Usage

Each module is designed to be used with Terragrunt or as a standalone Terraform module. See the `kubernetes-live` repo for example usage.

## Variables

Modules are highly dynamic—most values (e.g., versions, namespaces, addresses) are configurable via variables.

## Planned Improvements

### DNS Module
- [ ] Refactor DNS module to use HashiCorp's DNS provider (https://registry.terraform.io/providers/hashicorp/dns/latest/docs)
  - Replace manual BIND configuration with declarative Terraform DNS records
  - Manage DNS zones through Terraform
  - Implement proper state management for DNS records
  - Add support for dynamic DNS updates through Terraform
  - Benefits:
    - Declarative DNS management
    - Better state tracking
    - Easier integration with other Terraform resources
    - More maintainable and testable code

## Contributing

Feel free to open issues or PRs for improvements!
