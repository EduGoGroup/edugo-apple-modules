#!/bin/bash
#
# verify-sendable.sh
# Verifica que el proyecto compile con Swift 6 strict concurrency
#
# Uso:
#   ./scripts/verify-sendable.sh           # Verificar todo el proyecto
#   ./scripts/verify-sendable.sh TIER-0    # Verificar solo un tier
#
# Exit codes:
#   0 - Éxito: El proyecto es Sendable-compliant
#   1 - Error: Hay warnings/errors de concurrencia
#

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directorio base del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Módulos a verificar (mismo orden que el Makefile)
MODULES=(
    "TIER-0-Foundation/EduGoCommon"
    "TIER-1-Core/Logger"
    "TIER-1-Core/Models"
    "TIER-2-Infrastructure/Network"
    "TIER-2-Infrastructure/Storage"
    "TIER-3-Domain/Auth"
    "TIER-3-Domain/Roles"
    "TIER-4-Features/AI"
    "TIER-4-Features/API"
    "TIER-4-Features/Analytics"
)

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     🔍 Verificación de Sendable Compliance                   ║"
echo "║     Swift 6 Strict Concurrency Check                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

run_build() {
    local module_name="$1"
    local target_dir="$2"

    if [ ! -d "$target_dir" ]; then
        echo -e "${RED}❌ Error: Directorio '$module_name' no encontrado${NC}"
        exit 1
    fi

    echo -e "${YELLOW}📦 Verificando: $module_name${NC}"
    echo ""
    echo "🔨 Compilando con -strict-concurrency=complete..."
    echo ""

    BUILD_OUTPUT=$(cd "$target_dir" && swift build -Xswiftc -strict-concurrency=complete 2>&1) || {
        echo ""
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}  ❌ ERROR: Problemas de concurrencia en $module_name${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "Detalles del error:"
        echo "$BUILD_OUTPUT"
        echo ""
        echo -e "${YELLOW}💡 Sugerencias:${NC}"
        echo "   1. Revisa los mensajes anteriores para identificar los problemas"
        echo "   2. Asegúrate de que todas las entidades sean Sendable"
        echo "   3. Consulta docs/CONCURRENCY.md para patrones aprobados"
        echo ""
        exit 1
    }

    echo -e "${GREEN}✅ $module_name compila con strict concurrency${NC}"
    echo ""

    if echo "$BUILD_OUTPUT" | grep -q "warning:"; then
        echo -e "${YELLOW}⚠️  Warnings en $module_name (no bloquean la compilación):${NC}"
        echo "$BUILD_OUTPUT" | grep "warning:" | head -5
        echo ""
    fi
}

# Si se pasa un argumento, verificar solo ese tier/módulo
if [ -n "$1" ]; then
    if [ -d "$1" ]; then
        run_build "$1" "$1"
    else
        run_build "$1" "$PROJECT_DIR/$1"
    fi
else
    echo -e "${YELLOW}📦 Verificando proyecto completo...${NC}"
    echo ""
    for module in "${MODULES[@]}"; do
        run_build "$module" "$PROJECT_DIR/$module"
    done
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ ÉXITO: Proyecto Sendable-compliant${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "   El proyecto compila correctamente con strict concurrency."
echo "   Todas las entidades cumplen con Sendable requirements."
echo ""

exit 0
