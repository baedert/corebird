

macro (compile_resources RESOURCES_FILE OUTPUT_FILE)
  execute_process (COMMAND glib-compile-resources ${RESOURCES_FILE} --target=${OUTPUT_FILE} --generate-source)
endmacro (compile_resources)
