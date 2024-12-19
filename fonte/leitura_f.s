.section .note.GNU-stack,"",@progbits

.text

.globl ler_float

# Recebe o endereço de um 'float' como parâmetro e o preenche com 
# um número lido da entrada padrão.

ler_float:
    pushq %rbp                  #
    movq %rsp, %rbp             # Abertura da função. Aumenta a pilha em 48 bytes.
    subq $48, %rsp              #

    movq %rdi, 32(%rsp)         # Empilha o endereço recebido como parâmetro em 32(%rsp).
    movq %rsp, %rdi             # Passa o topo da pilha como parâmetro para a função "ler_string".
    call ler_string             # %rsp contém o endereço para o início do buffer de 32 bytes.

    movq %rbx, 40(%rsp)         # Preserva o valor antigo de %rbx na memória.
    movq %rsp, %rdi             # Passa o topo da pilha como parâmetro para a função "conv",
    call conv                   # que converterá a string em um número em ponto flutuante.

    movq 40(%rsp), %rbx         # Recupera o valor antigo de %rbx.
    movq 32(%rsp), %rdi         # Busca na memória o endereço passado como parâmetro e coloca
    movss %xmm0, (%rdi)         # nele o valor de retorno da função "conv".

    addq $48, %rsp              # 
    popq %rbp                   # Encerramento da função. Sem valor de retorno.
    ret                         # 



# Recebe um buffer de 32 bytes como parâmetro e o preenche com os caracteres 
# lidos da entrada padrão, colocando o caractere '\0' no final da string lida.

ler_string:
    pushq %rbp                  #
    movq %rsp, %rbp             # Abertura da função. Aumenta a pilha em 16 bytes.
    subq $16, %rsp              # 

    xor %eax, %eax              #
    movq %rdi, %rsi             # Lê 32 caracteres da entrada padrão no endereço
    xor %edi, %edi              # passado como parâmetro.
    movl $32, %edx              #
    syscall                     #

    movl $-1, %ecx

.w1:
    inc %ecx                    # Incrementa o índice.
    movb (%rsi, %rcx), %al      # Move um caractere do buffer para %al.
    cmpl $32, %ecx              # Verifica se o índice chegou a 32 (fim do buffer ultrapassado),
    je .w2                      # caso sim, vai para .w2.
    cmpb $10, %al               # Verifica se o caractere analisado é 'ENTER', caso não,
    jne .w1                     # retorna para o início do laço para olhar o próximo caractere.

    movb $0, (%rsi, %rcx)       # Caso a string tenha chegado ao fim, substitui
    jmp .fim2                   # o 'ENTER' pelo caractere '\0' e vai para o encerramento da função.

.w2:
    xor %eax, %eax              #
    xor %edi, %edi              # Laço para fazer leituras sucessivas de 16 em 16
    movq %rsp, %rsi             # bytes da entrada padrão no espaço alocado na pilha,
    movl $16, %edx              # até que o buffer do teclado esteja vazio.
    syscall                     #

    movl $-1, %ecx

.w2_1:
    inc %ecx                    # Verifica cada caractere no buffer da pilha 
    movb (%rsi, %rcx), %al      # até encontrar um 'ENTER', caso que indica
    cmpl $16, %ecx              # que o buffer do teclado foi esvaziado.
    je .w2                      # Caso o contador chegue a 16 e o 'ENTER' 
    cmpb $10, %al               # ainda não tenha sido encontrado, faz nova
    jne .w2_1                   # leitura da entrada padrão.

.fim2:
    addq $16, %rsp              #
    popq %rbp                   # Encerramento da função. Sem valor de retorno.
    ret                         #



# Recebe uma string de caracteres como parâmetro e a converte em um número em
# ponto flutuante de precisão simples (4 bytes), devolvido pela função em %xmm0.

conv:
    pushq %rbp                  # 
    movq %rsp, %rbp             # Abertura da função. Aumenta a pilha em 16 bytes.
    subq $16, %rsp              #

    movl $0, (%rsp)             # %xmm0 acumula o resultado.
    cvtsi2ss (%rsp), %xmm0      #

    movl $1, 4(%rsp)            # %xmm1 recebe o contador de casas decimais do número.
    cvtsi2ss 4(%rsp), %xmm1     # (Inicia em 1 e é multiplicado por 10 a cada casa decimal lida).

    movl $48, %eax              # %xmm2 contém o valor 48.
    cvtsi2ss %eax, %xmm2

    movl $10, %eax              # %xmm3 contém o valor 10.
    cvtsi2ss %eax, %xmm3

    movb (%rdi), %bl            # Passa o primeiro caractere para %bl.
    cmpb $45, %bl               # Caso o primeiro caractere seja (-), 
    sete %cl                    # %cl recebe 1 e 0 caso contrário.
    xorb %dl, %dl               # %dl = 0.

    dec %ecx

.ite:
    inc %ecx                    #  
    movb (%rdi, %rcx), %al      # Caractere da string é comparado ao número "0",
    cmpb $0, %al                # que indica o fim da string.
    je .sign                    #

    cmpb $0, %dl                # Indicador de estado do programa: %dl é 1 se estão sendo
    jne .L1                     # processadas as casas decimais do número e 0 caso contrário.
    cmpb $46, %al               #
    je .L0                      # Casas decimais podem ser separadas da parte inteira 
    cmpb $44, %al               # por ponto (ascii 46) ou vírgula (ascii 44).
    jne .L1                     #

.L0:
    movb $1, %dl                # Altera o estado do programa
    jmp .ite                    # em %dl e reinicia o laço.

.L1:
    cmpb $58, %al               # 
    jge .ite                    # Caso o caractere não seja numérico,
    cmpb $48, %al               # ignora-o e reinicia o laço.
    jl .ite                     # 

    cvtsi2ss %eax, %xmm4        # Registrador auxiliar %xmm4 recebe o valor numérico representado
    subss %xmm2, %xmm4          # pelo caractere em %al convertido para ponto flutuante.

    cmpb $1, %dl                # 
    jne .L2                     # 

    mulss %xmm3, %xmm1          # Caso o caractere esteja na mantissa do número, multiplica 
    divss %xmm1, %xmm4          # %xmm1 por 10 e divide %xmm4 (aux) por esse produto.
    jmp .L3

.L2:                            # Caso o caractere esteja na parte inteira do número,
    mulss %xmm3, %xmm0          # multiplica o acumulador por 10.

.L3:
    addss %xmm4, %xmm0          # acumulador = acumulador + aux
    jmp .ite                    # Retorna para o início do laço

.sign:
    cmpb $45, %bl               #
    jne .fim                    #

    movl $-1, %eax              # Caso o caractere lido no início do programa tenha sido um (-),
    cvtsi2ss %eax, %xmm1        # indicando número negativo, multiplica o acumulador por -1.
    mulss %xmm1, %xmm0          #    

.fim:
    addq $16, %rsp              # 
    popq %rbp                   # Encerrando a função. Resultado em %xmm0.
    ret                         # 
