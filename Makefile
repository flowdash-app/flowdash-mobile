.PHONY: help build watch build-delete watch-delete

.DEFAULT_GOAL := help

help:
	@echo "Available commands:"
	@echo ""
	@echo "  make build        - Run build_runner build with --delete-conflicting-outputs"
	@echo "  make watch        - Run build_runner watch with --delete-conflicting-outputs"
	@echo "  make help         - Show this help message"

build build-delete:
	dart run build_runner build --delete-conflicting-outputs

watch watch-delete:
	dart run build_runner watch --delete-conflicting-outputs

