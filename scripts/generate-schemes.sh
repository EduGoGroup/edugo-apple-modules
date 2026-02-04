#!/bin/bash
# generate-schemes.sh
# Script para generar schemes compartidos para todos los módulos SPM

set -e

echo "🚀 Generando schemes para módulos SPM de EduGo Apple Modules..."
echo ""

# Lista de módulos por TIER
TIER0_MODULES=("TIER-0-Foundation/EduGoCommon")
TIER1_MODULES=("TIER-1-Core/Logger" "TIER-1-Core/Models" "TIER-1-Core/Utilities")
TIER2_INFRA_MODULES=("TIER-2-Infrastructure/Network" "TIER-2-Infrastructure/Storage" "TIER-2-Infrastructure/LocalPersistence")
TIER2_DOMAIN_MODULES=("TIER-2-Domain/CQRS" "TIER-2-Domain/StateManagement" "TIER-2-Domain/UseCases")
TIER3_DOMAIN_MODULES=("TIER-3-Domain/Auth" "TIER-3-Domain/Roles")
TIER3_PRES_MODULES=("TIER-3-Presentation/Theme" "TIER-3-Presentation/UI" "TIER-3-Presentation/Navigation" "TIER-3-Presentation/Binding" "TIER-3-Presentation/Accessibility")
TIER3_VM_MODULES=("TIER-3-ViewModels/ViewModels")
TIER4_MODULES=("TIER-4-Features/AI" "TIER-4-Features/Analytics" "TIER-4-Features/API")

# Combinar todos los módulos
ALL_MODULES=(
    "${TIER0_MODULES[@]}"
    "${TIER1_MODULES[@]}"
    "${TIER2_INFRA_MODULES[@]}"
    "${TIER2_DOMAIN_MODULES[@]}"
    "${TIER3_DOMAIN_MODULES[@]}"
    "${TIER3_PRES_MODULES[@]}"
    "${TIER3_VM_MODULES[@]}"
    "${TIER4_MODULES[@]}"
)

# Directorio base
BASE_DIR="/Users/jhoanmedina/source/EduGo/EduUI/Modules/Apple"
cd "$BASE_DIR"

# Contador de éxitos
SUCCESS_COUNT=0
TOTAL_COUNT=${#ALL_MODULES[@]}

# Para cada módulo, resolver dependencias SPM
for module_path in "${ALL_MODULES[@]}"; do
    MODULE_NAME=$(basename "$module_path")
    echo "📦 Procesando módulo: $MODULE_NAME ($module_path)"

    if [ -d "$module_path" ]; then
        cd "$BASE_DIR/$module_path"

        # Verificar que existe Package.swift
        if [ -f "Package.swift" ]; then
            # Resolver dependencias
            if swift package resolve 2>/dev/null; then
                echo "   ✓ Dependencias resueltas para $MODULE_NAME"
                ((SUCCESS_COUNT++))
            else
                echo "   ⚠ Error al resolver dependencias para $MODULE_NAME"
            fi
        else
            echo "   ⚠ No se encontró Package.swift en $module_path"
        fi

        cd "$BASE_DIR"
    else
        echo "   ⚠ Directorio no encontrado: $module_path"
    fi
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Proceso completado: $SUCCESS_COUNT/$TOTAL_COUNT módulos procesados"
echo ""
echo "📝 Pasos siguientes:"
echo "   1. Abrir EduGoAppleModules.xcworkspace en Xcode"
echo "   2. Product → Scheme → Manage Schemes"
echo "   3. Marcar checkbox 'Shared' para cada scheme generado"
echo "   4. Los schemes compartidos se guardarán en .swiftpm/xcode/xcshareddata/xcschemes/"
echo ""
echo "💡 Tip: Los schemes ya existentes (Logger, AI) pueden servir como referencia"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
