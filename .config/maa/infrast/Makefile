# Convert YAML to JSON automatically

all: $(patsubst %.yaml,%.json,$(wildcard *.yaml))

%.json: %.yaml
	maa convert $< $@
	prettier --write $@
