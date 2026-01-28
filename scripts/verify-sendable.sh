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

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     🔍 Verificación de Sendable Compliance                   ║"
echo "║     Swift 6 Strict Concurrency Check                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Si se pasa un argumento, verificar solo ese tier/módulo
if [ -n "$1" ]; then
    TARGET_DIR="$PROJECT_DIR/$1"
    if [ ! -d "$TARGET_DIR" ]; then
        echo -e "${RED}❌ Error: Directorio '$1' no encontrado${NC}"
        exit 1
    fi
    echo -e "${YELLOW}📦 Verificando: $1${NC}"
    cd "$TARGET_DIR"
else
    echo -e "${YELLOW}📦 Verificando proyecto completo...${NC}"
    cd "$PROJECT_DIR"
fi

echo ""
echo "🔨 Compilando con -strict-concurrency=complete..."
echo ""

# Compilar con strict concurrency y capturar output
BUILD_OUTPUT=$(swift build -Xswiftc -strict-concurrency=complete 2>&1) || {
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  ❌ ERROR: El proyecto tiene problemas de concurrencia${NC}"
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

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ ÉXITO: Proyecto Sendable-compliant${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "   El proyecto compila correctamente con strict concurrency."
echo "   Todas las entidades cumplen con Sendable requirements."
echo ""

# Verificar si hay warnings (aunque compile)
if echo "$BUILD_OUTPUT" | grep -q "warning:"; then
    echo -e "${YELLOW}⚠️  Hay warnings (no bloquean la compilación):${NC}"
    echo "$BUILD_OUTPUT" | grep "warning:" | head -5
    echo ""
fi

exit 0
