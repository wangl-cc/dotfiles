.PHONY: all fix-dict

all: catppuccin.yaml

DICTS := $(wildcard *.dict.yaml)
NO_SYMLINK_DICTS := $(filter-out symlink%.dict.yaml, $(DICTS))

fix-dict:
	python3 fix_dict.py $(NO_SYMLINK_DICTS)

%.yaml: %.tera
	whiskers $< > $@
