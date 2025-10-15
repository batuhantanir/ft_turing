NAME = ft_turing
CC = ocamlc
CFLAGS = -g -w A-4-9-41-42-44-49
FILES = main.ml
BUILD_DIR = build/
CMO_FILES = $(FILES:.ml=.cmo)
BUILD_CMO_FILES = $(addprefix $(BUILD_DIR), $(CMO_FILES))

all: $(BUILD_DIR) $(NAME)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)%.cmo: %.ml | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(NAME): $(BUILD_CMO_FILES)
	$(CC) $(CFLAGS) -o $(NAME) $(BUILD_CMO_FILES)

clean:
	rm -rf $(BUILD_DIR)

fclean: clean
	rm -f $(NAME)

re: fclean all