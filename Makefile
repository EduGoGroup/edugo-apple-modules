# Makefile para EduGo Apple Modules
# Swift 6.2 Multi-Module Project

.PHONY: help build test clean test-verbose build-release test-coverage list-modules

# Colores para output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
RESET  := \033[0m

# Módulos por tier
TIER_0_MODULES := TIER-0-Foundation/EduGoCommon
TIER_1_MODULES := TIER-1-Core/Logger TIER-1-Core/Models
TIER_2_MODULES := TIER-2-Infrastructure/Network TIER-2-Infrastructure/Storage TIER-2-Infrastructure/LocalPersistence
TIER_3_MODULES := TIER-3-Domain/Auth TIER-3-Domain/Roles
TIER_4_MODULES := TIER-4-Features/AI TIER-4-Features/API TIER-4-Features/Analytics

ALL_MODULES := $(TIER_0_MODULES) $(TIER_1_MODULES) $(TIER_2_MODULES) $(TIER_3_MODULES) $(TIER_4_MODULES)

## help: Muestra este mensaje de ayuda
help:
	@echo "$(GREEN)EduGo Apple Modules - Makefile$(RESET)"
	@echo ""
	@echo "$(YELLOW)Comandos disponibles:$(RESET)"
	@echo ""
	@grep -E '^## ' Makefile | sed 's/## /  /'
	@echo ""
	@echo "$(YELLOW)Módulos por TIER:$(RESET)"
	@echo "  TIER-0 (Foundation): EduGoCommon"
	@echo "  TIER-1 (Core):       Logger, Models"
	@echo "  TIER-2 (Infrastructure): Network, Storage, LocalPersistence"
	@echo "  TIER-3 (Domain):     Auth, Roles"
	@echo "  TIER-4 (Features):   AI, API, Analytics"
	@echo ""

## build: Compila todos los módulos en orden de dependencias
build:
	@echo "$(GREEN)Compilando todos los módulos...$(RESET)"
	@for module in $(ALL_MODULES); do \
		echo "$(YELLOW)→ Compilando $$module$(RESET)"; \
		cd $$module && swift build || exit 1; \
		cd - > /dev/null; \
	done
	@echo "$(GREEN)✓ Compilación completa exitosa$(RESET)"

## build-release: Compila todos los módulos en modo release
build-release:
	@echo "$(GREEN)Compilando todos los módulos (Release)...$(RESET)"
	@for module in $(ALL_MODULES); do \
		echo "$(YELLOW)→ Compilando $$module (Release)$(RESET)"; \
		cd $$module && swift build -c release || exit 1; \
		cd - > /dev/null; \
	done
	@echo "$(GREEN)✓ Compilación Release completa exitosa$(RESET)"

## test: Ejecuta todos los tests de todos los módulos
test:
	@echo "$(GREEN)Ejecutando tests de todos los módulos...$(RESET)"
	@echo ""
	@PASSED=0; FAILED=0; \
	for module in $(ALL_MODULES); do \
		echo "$(YELLOW)→ Testing $$module$(RESET)"; \
		if cd $$module && swift test 2>&1 | tail -5; then \
			PASSED=$$((PASSED + 1)); \
			echo "$(GREEN)  ✓ $$module: PASSED$(RESET)"; \
		else \
			FAILED=$$((FAILED + 1)); \
			echo "$(RED)  ✗ $$module: FAILED$(RESET)"; \
		fi; \
		cd - > /dev/null; \
		echo ""; \
	done; \
	echo "$(YELLOW)========================================$(RESET)"; \
	echo "$(GREEN)Módulos pasados: $$PASSED$(RESET)"; \
	if [ $$FAILED -gt 0 ]; then \
		echo "$(RED)Módulos fallidos: $$FAILED$(RESET)"; \
		exit 1; \
	else \
		echo "$(GREEN)✓ Todos los tests pasaron$(RESET)"; \
	fi

## test-verbose: Ejecuta tests con output completo
test-verbose:
	@echo "$(GREEN)Ejecutando tests (verbose) de todos los módulos...$(RESET)"
	@for module in $(ALL_MODULES); do \
		echo "$(YELLOW)======================================== $$module ========================================$(RESET)"; \
		cd $$module && swift test || exit 1; \
		cd - > /dev/null; \
		echo ""; \
	done
	@echo "$(GREEN)✓ Todos los tests pasaron$(RESET)"

## test-tier-0: Ejecuta tests solo de TIER-0
test-tier-0:
	@echo "$(GREEN)Testing TIER-0 (Foundation)...$(RESET)"
	@for module in $(TIER_0_MODULES); do \
		echo "$(YELLOW)→ Testing $$module$(RESET)"; \
		cd $$module && swift test || exit 1; \
		cd - > /dev/null; \
	done

## test-tier-1: Ejecuta tests solo de TIER-1
test-tier-1:
	@echo "$(GREEN)Testing TIER-1 (Core)...$(RESET)"
	@for module in $(TIER_1_MODULES); do \
		echo "$(YELLOW)→ Testing $$module$(RESET)"; \
		cd $$module && swift test || exit 1; \
		cd - > /dev/null; \
	done

## test-tier-2: Ejecuta tests solo de TIER-2
test-tier-2:
	@echo "$(GREEN)Testing TIER-2 (Infrastructure)...$(RESET)"
	@for module in $(TIER_2_MODULES); do \
		echo "$(YELLOW)→ Testing $$module$(RESET)"; \
		cd $$module && swift test || exit 1; \
		cd - > /dev/null; \
	done

## test-tier-3: Ejecuta tests solo de TIER-3
test-tier-3:
	@echo "$(GREEN)Testing TIER-3 (Domain)...$(RESET)"
	@for module in $(TIER_3_MODULES); do \
		echo "$(YELLOW)→ Testing $$module$(RESET)"; \
		cd $$module && swift test || exit 1; \
		cd - > /dev/null; \
	done

## test-tier-4: Ejecuta tests solo de TIER-4
test-tier-4:
	@echo "$(GREEN)Testing TIER-4 (Features)...$(RESET)"
	@for module in $(TIER_4_MODULES); do \
		echo "$(YELLOW)→ Testing $$module$(RESET)"; \
		cd $$module && swift test || exit 1; \
		cd - > /dev/null; \
	done

## clean: Limpia archivos de build de todos los módulos
clean:
	@echo "$(YELLOW)Limpiando archivos de build...$(RESET)"
	@for module in $(ALL_MODULES); do \
		echo "$(YELLOW)→ Limpiando $$module$(RESET)"; \
		cd $$module && swift package clean 2>/dev/null || true; \
		cd - > /dev/null; \
	done
	@echo "$(GREEN)✓ Limpieza completa$(RESET)"

## clean-build: Limpia y recompila todo
clean-build: clean build

## list-modules: Lista todos los módulos del proyecto
list-modules:
	@echo "$(GREEN)Módulos del proyecto EduGo Apple:$(RESET)"
	@echo ""
	@echo "$(YELLOW)TIER-0 (Foundation):$(RESET)"
	@for module in $(TIER_0_MODULES); do echo "  - $$module"; done
	@echo ""
	@echo "$(YELLOW)TIER-1 (Core):$(RESET)"
	@for module in $(TIER_1_MODULES); do echo "  - $$module"; done
	@echo ""
	@echo "$(YELLOW)TIER-2 (Infrastructure):$(RESET)"
	@for module in $(TIER_2_MODULES); do echo "  - $$module"; done
	@echo ""
	@echo "$(YELLOW)TIER-3 (Domain):$(RESET)"
	@for module in $(TIER_3_MODULES); do echo "  - $$module"; done
	@echo ""
	@echo "$(YELLOW)TIER-4 (Features):$(RESET)"
	@for module in $(TIER_4_MODULES); do echo "  - $$module"; done
	@echo ""
	@echo "$(GREEN)Total: 9 módulos$(RESET)"

## verify: Verifica la estructura del proyecto
verify:
	@echo "$(GREEN)Verificando estructura del proyecto...$(RESET)"
	@MISSING=0; \
	for module in $(ALL_MODULES); do \
		if [ ! -f "$$module/Package.swift" ]; then \
			echo "$(RED)✗ Package.swift faltante en $$module$(RESET)"; \
			MISSING=$$((MISSING + 1)); \
		else \
			echo "$(GREEN)✓ $$module$(RESET)"; \
		fi; \
	done; \
	if [ $$MISSING -gt 0 ]; then \
		echo "$(RED)✗ Estructura incompleta: $$MISSING módulos con problemas$(RESET)"; \
		exit 1; \
	else \
		echo "$(GREEN)✓ Estructura del proyecto correcta$(RESET)"; \
	fi

## format: Formatea el código Swift (requiere swift-format)
format:
	@echo "$(YELLOW)Formateando código Swift...$(RESET)"
	@if command -v swift-format >/dev/null 2>&1; then \
		for module in $(ALL_MODULES); do \
			echo "$(YELLOW)→ Formateando $$module$(RESET)"; \
			find $$module/Sources -name "*.swift" -exec swift-format -i {} \; 2>/dev/null || true; \
			find $$module/Tests -name "*.swift" -exec swift-format -i {} \; 2>/dev/null || true; \
		done; \
		echo "$(GREEN)✓ Formateo completo$(RESET)"; \
	else \
		echo "$(RED)✗ swift-format no está instalado$(RESET)"; \
		echo "  Instalar con: brew install swift-format"; \
		exit 1; \
	fi

## lint: Ejecuta SwiftLint (requiere swiftlint)
lint:
	@echo "$(YELLOW)Ejecutando SwiftLint...$(RESET)"
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint lint --strict; \
	else \
		echo "$(RED)✗ swiftlint no está instalado$(RESET)"; \
		echo "  Instalar con: brew install swiftlint"; \
		exit 1; \
	fi

## xcode: Genera proyecto Xcode (experimental)
xcode:
	@echo "$(YELLOW)Generando proyecto Xcode...$(RESET)"
	@echo "$(RED)Nota: Este proyecto usa SPM multi-módulo.$(RESET)"
	@echo "$(YELLOW)Abre cada módulo individualmente en Xcode.$(RESET)"
	@for module in $(ALL_MODULES); do \
		echo "  → $$module/Package.swift"; \
	done

## stats: Muestra estadísticas del proyecto
stats:
	@echo "$(GREEN)Estadísticas del proyecto EduGo Apple:$(RESET)"
	@echo ""
	@echo "$(YELLOW)Archivos Swift por módulo:$(RESET)"
	@for module in $(ALL_MODULES); do \
		COUNT=$$(find $$module/Sources -name "*.swift" 2>/dev/null | wc -l | tr -d ' '); \
		echo "  $$module: $$COUNT archivos"; \
	done
	@echo ""
	@TOTAL_SWIFT=$$(find . -path "*/Sources/*.swift" -o -path "*/Tests/*.swift" | wc -l | tr -d ' '); \
	TOTAL_LINES=$$(find . -path "*/Sources/*.swift" -o -path "*/Tests/*.swift" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $$1}'); \
	echo "$(GREEN)Total archivos Swift: $$TOTAL_SWIFT$(RESET)"; \
	echo "$(GREEN)Total líneas de código: $$TOTAL_LINES$(RESET)"

## ci: Ejecuta pipeline completo (verify, build, test)
ci: verify build test
	@echo "$(GREEN)✓ Pipeline CI completo exitoso$(RESET)"
