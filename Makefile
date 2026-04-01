SHELL := /usr/bin/env bash

.PHONY: dbt-debug dbt-run dbt-test dbt-docs-generate dbt-docs-serve dbt-ls

dbt-debug:
	./run_dbt.sh debug

dbt-run:
	./run_dbt.sh run

dbt-test:
	./run_dbt.sh test

dbt-docs-generate:
	./run_dbt.sh docs generate

dbt-docs-serve:
	./run_dbt.sh docs serve

dbt-ls:
	./run_dbt.sh ls --resource-type model --output name
