SCRIPTS_DIR := scripts

.PHONY: sync update build up all

sync:
	@bash $(SCRIPTS_DIR)/sync.sh

update:
	@bash $(SCRIPTS_DIR)/update.sh

build:
	@docker compose build

up:
	@docker compose up

all: sync update build up
