CLI_TOOL_NAME = flutter_cwa_plugin
PLUGIN_DIRECTORY= ~/.config/cwa/plugins

build:
	@dart compile exe bin/${CLI_TOOL_NAME}.dart -o ./bin/${CLI_TOOL_NAME}

run:
	@dart run

run-exec: build
	@./bin/${CLI_TOOL_NAME}

globalise: build
	@mkdir -p ${PLUGIN_DIRECTORY}
	@cp ./bin/${CLI_TOOL_NAME} ${PLUGIN_DIRECTORY}/

