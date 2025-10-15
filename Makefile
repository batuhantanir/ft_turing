OCAMLC    = ocamlfind ocamlc
OCAMLOPT  = ocamlfind ocamlopt
OCAMLDEP  = ocamldep

TARGET_NATIVE = ft_turing
TARGET_BYTE   = ft_turing.byte
BUILD_DIR     = build
UTILS_DIR     = src/utils

MAIN_SRC = src/turing.ml src/main.ml

UTILS_SOURCES = $(shell find $(UTILS_DIR) -name '*.ml' 2>/dev/null | sort)

ALL_SOURCES = $(UTILS_SOURCES) $(MAIN_SRC)

CMX_FILES = $(patsubst %.ml,$(BUILD_DIR)/%.cmx,$(notdir $(ALL_SOURCES)))
CMI_FILES = $(patsubst %.ml,$(BUILD_DIR)/%.cmi,$(notdir $(ALL_SOURCES)))
CMO_FILES = $(patsubst %.ml,$(BUILD_DIR)/%.cmo,$(notdir $(ALL_SOURCES)))

PACKAGES    = yojson
PKG_FLAGS   = -package $(PACKAGES)

NATIVE_LIBS = unix.cmxa
BYTE_LIBS   = unix.cma
INCLUDES    = -I $(BUILD_DIR)
WARNINGS    = -w A-4-9-41-42-44-49
DEBUG       = -g
OCAMLFLAGS  = $(DEBUG) $(WARNINGS) $(INCLUDES) $(PKG_FLAGS)

all: native

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.cmx: $(UTILS_DIR)/*/%.ml | $(BUILD_DIR)
	@echo "Compiling $< -> $@"
	$(OCAMLOPT) $(OCAMLFLAGS) -c $< -o $@

$(BUILD_DIR)/%.cmx: src/%.ml | $(BUILD_DIR)
	@echo "Compiling $< -> $@"
	$(OCAMLOPT) $(OCAMLFLAGS) -c $< -o $@

# Ensure main is compiled after turing to satisfy module deps
$(BUILD_DIR)/main.cmx: $(BUILD_DIR)/turing.cmx

native: $(TARGET_NATIVE)

$(TARGET_NATIVE): $(CMX_FILES)
	@echo "Linking $@"
	$(OCAMLOPT) $(OCAMLFLAGS) -linkpkg $(NATIVE_LIBS) $(CMX_FILES) -o $@

byte: $(TARGET_BYTE)

$(TARGET_BYTE): $(ALL_SOURCES) | $(BUILD_DIR)
	@echo "Compiling byte code"
	$(OCAMLC) $(DEBUG) $(WARNINGS) $(PKG_FLAGS) -linkpkg -I $(BUILD_DIR) $(BYTE_LIBS) $(ALL_SOURCES) -o $@

clean:
	@echo "Cleaning build artifacts"
	@rm -rf $(BUILD_DIR)

fclean: clean
	@echo "Cleaning binaries"
	@rm -f $(TARGET_NATIVE) $(TARGET_BYTE)

re: fclean all

show-sources:
	@echo "Source files (in compilation order):"
	@echo "$(ALL_SOURCES)" | tr ' ' '\n' | nl

show-deps:
	@echo "CMX files: $(CMX_FILES)"
	@echo "Utils sources: $(UTILS_SOURCES)"

.PHONY: all clean fclean re native byte show-sources show-deps