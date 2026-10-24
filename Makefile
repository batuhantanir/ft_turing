NAME    = ft_turing
SRC_DIR = src
OBJ_DIR = build
MODULES = errors types json parse validate tape utils cli machine_loop main
SRCS    = $(addprefix $(SRC_DIR)/,$(addsuffix .ml,$(MODULES)))

NATIVE_OBJS = $(addprefix $(OBJ_DIR)/,$(addsuffix .cmx,$(MODULES)))
BYTE_OBJS   = $(addprefix $(OBJ_DIR)/,$(addsuffix .cmo,$(MODULES)))

HAVE_OCAML_TOOLS := $(shell command -v ocamlopt >/dev/null 2>&1 && command -v ocamlc >/dev/null 2>&1 && echo yes)
OCAMLOPT = $(if $(HAVE_OCAML_TOOLS),ocamlopt,opam exec -- ocamlopt) -bin-annot
OCAMLC   = $(if $(HAVE_OCAML_TOOLS),ocamlc,opam exec -- ocamlc) -bin-annot

.PHONY: all clean fclean re byte check-deps

all: $(NAME)

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

check-deps:
	@if ! command -v ocamlopt >/dev/null 2>&1 || ! command -v ocamlc >/dev/null 2>&1; then \
		if ! command -v opam >/dev/null 2>&1; then \
			echo "Error: OCaml tools are missing and OPAM is unavailable" >&2; exit 1; \
		fi; \
		if ! opam switch show >/dev/null 2>&1; then \
			opam switch create . --packages=ocaml-base-compiler -y || exit $$?; \
		else \
			opam install -y ocaml || exit $$?; \
		fi; \
	fi

$(NAME): $(SRCS) | $(OBJ_DIR) check-deps
	@for m in $(MODULES); do \
		$(OCAMLOPT) -I $(OBJ_DIR) -c -o $(OBJ_DIR)/$$m.cmx $(SRC_DIR)/$$m.ml || exit $$?; \
	done
	$(OCAMLOPT) -I $(OBJ_DIR) -o $(NAME) $(NATIVE_OBJS)

byte: $(SRCS) | $(OBJ_DIR) check-deps
	@for m in $(MODULES); do \
		$(OCAMLC) -I $(OBJ_DIR) -c -o $(OBJ_DIR)/$$m.cmo $(SRC_DIR)/$$m.ml || exit $$?; \
	done
	$(OCAMLC) -I $(OBJ_DIR) -o $(NAME).byte $(BYTE_OBJS)

clean:
	rm -rf $(OBJ_DIR)

fclean: clean
	rm -f $(NAME) $(NAME).byte

re: fclean all
