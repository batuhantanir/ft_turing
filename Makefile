NAME    = ft_turing
SRC_DIR = src
SRCS    = $(SRC_DIR)/json.ml $(SRC_DIR)/main.ml

OCAMLOPT = ocamlopt
OCAMLC   = ocamlc

.PHONY: all clean fclean re check_deps byte

all: check_deps $(NAME)

check_deps:
	@command -v ocamlopt > /dev/null 2>&1 || \
	  (echo "ocamlopt not found. Please install OCaml." && exit 1)
	@command -v ocamlc > /dev/null 2>&1 || \
	  (echo "ocamlc not found. Please install OCaml." && exit 1)

$(NAME): $(SRCS)
	$(OCAMLOPT) -c $(SRC_DIR)/json.ml
	$(OCAMLOPT) -I $(SRC_DIR) -c $(SRC_DIR)/main.ml
	$(OCAMLOPT) -o $(NAME) $(SRC_DIR)/json.cmx $(SRC_DIR)/main.cmx

byte: $(SRCS)
	$(OCAMLC) -I $(SRC_DIR) -c $(SRC_DIR)/json.ml
	$(OCAMLC) -I $(SRC_DIR) -c $(SRC_DIR)/main.ml
	$(OCAMLC) -o $(NAME).byte $(SRC_DIR)/json.cmo $(SRC_DIR)/main.cmo

clean:
	rm -f $(SRC_DIR)/*.cmi $(SRC_DIR)/*.cmo $(SRC_DIR)/*.cmx $(SRC_DIR)/*.o
	rm -f *.cmi *.cmo *.cmx *.o

fclean: clean
	rm -f $(NAME) $(NAME).byte

re: fclean all