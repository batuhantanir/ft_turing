NAME    = ft_turing
SRC_DIR = src
OBJ_DIR = build
MODULES = errors types json parse validate tape utils cli machine_loop main
SRCS    = $(addprefix $(SRC_DIR)/,$(addsuffix .ml,$(MODULES)))

NATIVE_OBJS = $(addprefix $(OBJ_DIR)/,$(addsuffix .cmx,$(MODULES)))
BYTE_OBJS   = $(addprefix $(OBJ_DIR)/,$(addsuffix .cmo,$(MODULES)))

OCAMLOPT = ocamlopt -bin-annot
OCAMLC   = ocamlc -bin-annot
OPAM     = opam
OPAM_SWITCH_DIR = _opam
OPAM_SWITCH = $(CURDIR)
OCAML_COMPILER = ocaml-base-compiler.5.2.0
OPAM_PACKAGES = ocamlfind ocamlformat ocaml-lsp-server merlin
OPAM_EXEC = $(OPAM) exec --switch=$(OPAM_SWITCH) --

.PHONY: all clean fclean re check_deps byte

all: check_deps $(NAME)

check_deps:
	@command -v $(OPAM) > /dev/null 2>&1 || \
	  (echo "Error: opam not found. Please install OPAM first." && exit 1)
	@if [ ! -d "$(OPAM_SWITCH_DIR)" ]; then \
		echo "Creating local OPAM switch with $(OCAML_COMPILER)..."; \
		$(OPAM) switch create $(OPAM_SWITCH) $(OCAML_COMPILER) --yes; \
	fi
	@$(OPAM) install --switch=$(OPAM_SWITCH) --yes $(OPAM_PACKAGES)
	@$(OPAM_EXEC) $(OCAMLOPT) -version > /dev/null 2>&1 || \
	  (echo "Error: ocamlopt missing in OPAM switch." && exit 1)
	@$(OPAM_EXEC) $(OCAMLC) -version > /dev/null 2>&1 || \
	  (echo "Error: ocamlc missing in OPAM switch." && exit 1)


$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

$(NAME): $(SRCS) | $(OBJ_DIR)
	@for m in $(MODULES); do \
		$(OPAM_EXEC) $(OCAMLOPT) -I $(OBJ_DIR) -c -o $(OBJ_DIR)/$$m.cmx $(SRC_DIR)/$$m.ml || exit $$?; \
	done
	$(OPAM_EXEC) $(OCAMLOPT) -I $(OBJ_DIR) -o $(NAME) $(NATIVE_OBJS)

byte: check_deps $(SRCS) | $(OBJ_DIR)
	@for m in $(MODULES); do \
		$(OPAM_EXEC) $(OCAMLC) -I $(OBJ_DIR) -c -o $(OBJ_DIR)/$$m.cmo $(SRC_DIR)/$$m.ml || exit $$?; \
	done
	$(OPAM_EXEC) $(OCAMLC) -I $(OBJ_DIR) -o $(NAME).byte $(BYTE_OBJS)

clean:
	rm -rf $(OBJ_DIR)

fclean: clean
	rm -f $(NAME) $(NAME).byte

re: fclean all