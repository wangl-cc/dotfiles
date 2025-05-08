# Convert YAML to JSON automatically

all: $(patsubst %.yaml,%.json,$(wildcard *.yaml))

%.json: %.yaml
	maa convert -fj $< | prettier --parser=json --log-level=warn > $@
