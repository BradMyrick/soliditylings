.PHONY: build verify-solutions check-solved watch run

build:
	@npm run build

# The gate: every exercise must have a working solved copy.
verify-solutions:
	@./misc/verify-solutions.sh

# Exercises in exercises/ must be listed in info.toml and have a solution twin.
check-solved:
	@./misc/check-exercises.sh

watch:
	@npm run start -- watch

run:
	@npm run start -- run
