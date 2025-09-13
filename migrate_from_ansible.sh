#!/bin/bash
# Migration script from Ansible/Uncletopia setup to Pterodactyl/Terraform

set -euo pipefail

echo "MGE.TF Ansible → Pterodactyl Migration Tool"
echo "==========================================="

# Paths
ANSIBLE_DIR="$(dirname "$0")"
TERRAFORM_DIR="${ANSIBLE_DIR}/terraform"
OUTPUT_DIR="${ANSIBLE_DIR}/migration_output"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Extract SourceMod plugins
echo "→ Extracting SourceMod plugins..."
if [ -d "${ANSIBLE_DIR}/sm_plugins" ]; then
    cp -r "${ANSIBLE_DIR}/sm_plugins" "${OUTPUT_DIR}/"
    echo "  ✓ Plugins copied to ${OUTPUT_DIR}/sm_plugins"
fi

# Extract configurations from group_vars
echo "→ Extracting configurations..."
for config_file in ${ANSIBLE_DIR}/group_vars/*.yml*; do
    if [ -f "$config_file" ]; then
        basename=$(basename "$config_file")
        # Convert YAML to terraform.tfvars format
        echo "  Processing $basename..."
        python3 - <<EOF
import yaml
import json
import sys

with open("$config_file", 'r') as f:
    data = yaml.safe_load(f)
    
# Extract relevant configs for Terraform
terraform_vars = {}

# Database config
if 'sourcemod_db_host' in data:
    terraform_vars['database_connection_string'] = f"mysql://{data.get('sourcemod_db_username', 'sourcemod')}:{data.get('sourcemod_db_password', '')}@{data['sourcemod_db_host']}:{data.get('sourcemod_db_port', 3306)}/sourcemod"

# Server configs
if 'srcds_hostname' in data:
    terraform_vars['default_server_name'] = data['srcds_hostname']
if 'srcds_rcon_password' in data:
    terraform_vars['default_rcon_password'] = data['srcds_rcon_password']
if 'fastdl_url' in data:
    terraform_vars['fastdl_url'] = data['fastdl_url']

# Write terraform vars
with open("${OUTPUT_DIR}/extracted_${basename%.yml*}.tfvars", 'w') as out:
    for key, value in terraform_vars.items():
        if isinstance(value, str):
            out.write(f'{key} = "{value}"\n')
        else:
            out.write(f'{key} = {json.dumps(value)}\n')
            
print(f"  ✓ Extracted to ${OUTPUT_DIR}/extracted_${basename%.yml*}.tfvars")
EOF
    fi
done

# Generate server.cfg from Ansible templates
echo "→ Generating server.cfg..."
cat > "${OUTPUT_DIR}/server.cfg" <<'EOF'
// Migrated from Ansible configuration
// MGE.TF Server Configuration

hostname "{{SERVER_NAME}}"
rcon_password "{{RCON_PASSWORD}}"
sv_password "{{SERVER_PASSWORD}}"

// Network settings (from Ansible)
sv_maxrate 0
sv_minrate 100000
sv_maxcmdrate 66
sv_mincmdrate 66
sv_maxupdaterate 66
sv_minupdaterate 66
fps_max 0

// MGE specific settings
mp_tournament 1
mp_tournament_restart
sv_alltalk 1
mp_forcecamera 0
sv_allow_votes 0
mp_timelimit 0
mp_winlimit 0
tf_weapon_criticals 0
tf_damage_disablespread 1
tf_use_fixed_weaponspreads 1

// Logging
log on
sv_logbans 1
sv_logecho 1
sv_logfile 1
sv_log_onefile 0

// Execute MGE config
exec mgemod
EOF
echo "  ✓ Generated ${OUTPUT_DIR}/server.cfg"

# Extract MGEMod configuration if exists
echo "→ Checking for MGEMod configs..."
if [ -f "${ANSIBLE_DIR}/roles/srcds/files/mgemod.cfg" ]; then
    cp "${ANSIBLE_DIR}/roles/srcds/files/mgemod.cfg" "${OUTPUT_DIR}/"
    echo "  ✓ Copied mgemod.cfg"
fi

# Generate Docker build script
echo "→ Creating Docker build script..."
cat > "${OUTPUT_DIR}/build_custom_egg.sh" <<'EOF'
#!/bin/bash
# Build custom TF2 MGE Docker image with extracted configs

cd "$(dirname "$0")"

# Create temporary docker context
DOCKER_CONTEXT=$(mktemp -d)
cp -r ../docker/* "${DOCKER_CONTEXT}/"

# Copy extracted configs
cp server.cfg "${DOCKER_CONTEXT}/configs/"
cp -r sm_plugins "${DOCKER_CONTEXT}/plugins/" 2>/dev/null || true

# Build image
docker build -t ghcr.io/mgetf/tf2-mge:custom "${DOCKER_CONTEXT}"

# Push to registry
echo "Push to registry? (y/n)"
read -r push
if [ "$push" = "y" ]; then
    docker push ghcr.io/mgetf/tf2-mge:custom
fi

# Cleanup
rm -rf "${DOCKER_CONTEXT}"
EOF
chmod +x "${OUTPUT_DIR}/build_custom_egg.sh"
echo "  ✓ Created ${OUTPUT_DIR}/build_custom_egg.sh"

# Generate Terraform migration variables
echo "→ Generating Terraform variables..."
cat > "${OUTPUT_DIR}/migration.tfvars" <<EOF
# Migration from Ansible setup
# Generated: $(date)

# Use existing configs
sourcemod_plugins = [
$(ls -1 ${ANSIBLE_DIR}/sm_plugins/*.sp 2>/dev/null | sed 's/.*\//  "/;s/\.sp/",/' | head -n -1)
$(ls -1 ${ANSIBLE_DIR}/sm_plugins/*.sp 2>/dev/null | tail -1 | sed 's/.*\//  "/;s/\.sp/"/')
]

# Custom Docker image with migrated configs
docker_image = "ghcr.io/mgetf/tf2-mge:custom"

# Preserve existing database if configured
$(grep -h "sourcemod_db" ${ANSIBLE_DIR}/group_vars/*.yml 2>/dev/null | head -5 | sed 's/^/# /')
EOF
echo "  ✓ Generated ${OUTPUT_DIR}/migration.tfvars"

# Summary
echo ""
echo "========================================="
echo "Migration Complete!"
echo "========================================="
echo ""
echo "Extracted files to: ${OUTPUT_DIR}/"
echo ""
echo "Next steps:"
echo "1. Review extracted configurations in ${OUTPUT_DIR}/"
echo "2. Copy terraform.tfvars.example to terraform.tfvars"
echo "3. Add your API credentials to terraform.tfvars"
echo "4. Merge settings from ${OUTPUT_DIR}/migration.tfvars"
echo "5. Run: cd terraform && terraform init && terraform apply"
echo ""
echo "To use custom configs in Docker:"
echo "  cd ${OUTPUT_DIR} && ./build_custom_egg.sh"
echo ""
echo "For gradual migration, you can run both systems in parallel"
echo "and migrate servers one by one via the Pterodactyl panel."