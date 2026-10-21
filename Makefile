.PHONY: test preview

NVIM ?= nvim

test:
	$(NVIM) --clean --headless -l tests/run.lua
	$(NVIM) --clean --headless -l tests/layout.lua
	$(NVIM) --clean --headless -l tests/recent.lua
	$(NVIM) --clean --headless -l tests/session.lua
	$(NVIM) --clean --headless -l tests/git.lua
	$(NVIM) --clean --headless -l tests/autoopen.lua
	$(NVIM) --clean --headless -l tests/conformance.lua

preview:
	$(NVIM) --clean --headless -l tests/preview.lua
