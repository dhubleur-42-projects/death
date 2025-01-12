NAME		=	Pestilence

SRCS		= 	\
				final_main.s

INCLUDES	=	includes/

_OBJS		=	${SRCS:.s=.o}
OBJS		=	$(addprefix build/, $(_OBJS))

NASM		=	nasm
NFLAGS		=	-felf64

LD			=	ld

all		:	$(NAME)

build/%.o	:	srcs/%.s
	@if [ ! -d $(dir $@) ]; then\
		mkdir -p $(dir $@);\
	fi
	$(NASM) ${NFLAGS} -I ${INCLUDES} $< -o $@

srcs/final_main.s	:	srcs/main.s
	./tools/convert_payload.sh

$(NAME)	:	$(OBJS)
	$(LD) $(OBJS) -o $(NAME)

clean	:	
	rm -Rf build/

fclean	:	clean
	rm -f ${NAME}

re		:	fclean
			make ${NAME}

test	:	${NAME}
	rm -rf /tmp/test
	rm -rf /tmp/test2
	mkdir -p /tmp/test
	cp /bin/echo /tmp/test
	./${NAME}

.PHONY	:	all clean fclean re test
