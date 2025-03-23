NAME		=	Death
TMP_NAME	=	build/$(NAME).tmp

SRCS		= 	\
				final_main.s

INCLUDES	=	includes/

_OBJS		=	${SRCS:.s=.o}
OBJS		=	$(addprefix build/, $(_OBJS))

NASM		=	nasm
NFLAGS		=	-felf64

ifeq (debug, $(filter debug,$(MAKECMDGOALS)))
	NFLAGS	+=	-g -D DEBUG
endif

LD			=	ld

EMPTY_PROGRAM	=	build/empty_program
EMPTY_SRC		=	srcs/empty.c

all		:	$(NAME)

debug	:	all
	@echo "[WARN] If the final_main.s was not regenerated in debug mode, the program will crash"

$(EMPTY_PROGRAM)	:	$(EMPTY_SRC)
	@if [ ! -d $(dir $@) ]; then\
		mkdir -p $(dir $@);\
	fi
	gcc -nostartfiles -static -nolibc -masm=intel  -o $(EMPTY_PROGRAM) $(EMPTY_SRC)

build/%.o	:	srcs/%.s
	@if [ ! -d $(dir $@) ]; then\
		mkdir -p $(dir $@);\
	fi
	$(NASM) ${NFLAGS} -I ${INCLUDES} $< -o $@

srcs/final_main.s	:	srcs/main.s
	./tools/convert_payload.sh "$(NFLAGS)"
	./tools/convert_variations.sh "$(NFLAGS)"

$(TMP_NAME)	:	$(OBJS)
	$(LD) $(OBJS) -o $(TMP_NAME)

$(NAME): $(TMP_NAME) $(EMPTY_PROGRAM)
ifeq (debug, $(filter debug,$(MAKECMDGOALS)))
	cp $(TMP_NAME) $(NAME)
else
	mkdir -p /tmp/test
	cp $(EMPTY_PROGRAM) /tmp/test
	./$(TMP_NAME)
	mv /tmp/test/$(notdir $(EMPTY_PROGRAM)) $(NAME)
endif

clean	:	
	rm -Rf build/
	rm -f srcs/final_main.s

fclean	:	clean
	rm -f ${NAME}

re		:	fclean
			make ${NAME}

.PHONY	:	all clean fclean re debug
