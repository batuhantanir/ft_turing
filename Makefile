NAME    = ft_turing
SRC_DIR = src
OBJ_DIR = build
MODULES = errors types json parse validate tape utils cli machine_loop main
SRCS    = $(addprefix $(SRC_DIR)/,$(addsuffix .ml,$(MODULES)))

NATIVE_OBJS = $(addprefix $(OBJ_DIR)/,$(addsuffix .cmx,$(MODULES)))
BYTE_OBJS   = $(addprefix $(OBJ_DIR)/,$(addsuffix .cmo,$(MODULES)))

OCAMLOPT = ocamlopt -bin-annot
OCAMLC   = ocamlc -bin-annot

.PHONY: all clean fclean re byte

all: $(NAME)

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

$(NAME): $(SRCS) | $(OBJ_DIR)
	@for m in $(MODULES); do \
		$(OCAMLOPT) -I $(OBJ_DIR) -c -o $(OBJ_DIR)/$$m.cmx $(SRC_DIR)/$$m.ml || exit $$?; \
	done
	$(OCAMLOPT) -I $(OBJ_DIR) -o $(NAME) $(NATIVE_OBJS)

byte: $(SRCS) | $(OBJ_DIR)
	@for m in $(MODULES); do \
		$(OCAMLC) -I $(OBJ_DIR) -c -o $(OBJ_DIR)/$$m.cmo $(SRC_DIR)/$$m.ml || exit $$?; \
	done
	$(OCAMLC) -I $(OBJ_DIR) -o $(NAME).byte $(BYTE_OBJS)

clean:
	rm -rf $(OBJ_DIR)

fclean: clean
	rm -f $(NAME) $(NAME).byte

re: fclean all