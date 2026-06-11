# #=============================================================================
#  Gerador de palavras 32b para memoria de rede neural
#   Formato esperado: (IN, H1, H2, ..., OUT)
# 
#        Mapa de memoria (32 bits):
#     |----------------------------------------------------------|
#     | 4b layers |    10b output   |         18b input          | 0x0000
#     |----------------------------------------------------------|
#     |            16b H1           |           16b H2           | 0x0001
#     |----------------------------------------------------------|
#     |            16b H3           |           16b H4           | 0x0002+ 
#     |----------------------------------------------------------|
#                                 .....
#-----------------------------------------------------------------------------
# Author: Lucas Farias
# Email:  lucas.martins@ee.ufcg.edu.br
# Date:   2026-05-21
# Obs:    Houve uso de LLM
#=============================================================================

from tabulate import tabulate

print("  __  __                          __  __                _           ")
print(" |  \/  |___ _ __  ___ _ _ _  _  |  \/  |__ _ _ __ _ __(_)_ _  __ _ ")
print(" | |\/| / -_) '  \/ _ \ '_| || | | |\/| / _` | '_ \ '_ \ | ' \/ _` |")
print(" |_|  |_\___|_|_|_\___/_|  \_, | |_|  |_\__,_| .__/ .__/_|_||_\__, |")
print("                           |__/              |_|  |_|         |___/ ")

# Configure sua rede AQUI:

shape = (784, 256, 128, 64, 10)
# shape = (784, 512, 256, 128, 64, 32, 16, 10)

#=========================================================
# Funcoes auxiliares
#=========================================================

def build_header_word(shape):
    """
    Palavra 0x0000

    [31:28] -> número de camadas hidden (4b)
    [27:18] -> output width (10b)
    [17:00] -> input width  (18b)
    """

    input_width = shape[0]
    output_width = shape[-1]
    hidden_layers = len(shape) - 2

    if hidden_layers > 0xF:
        raise ValueError("Máximo de 15 camadas hidden")

    if output_width > 0x3FF:
        raise ValueError("Output width excede 10 bits")

    if input_width > 0x3FFFF:
        raise ValueError("Input width excede 18 bits")

    word = (
        ((hidden_layers & 0xF) << 28)
        | ((output_width & 0x3FF) << 18)
        | (input_width & 0x3FFFF)
    )

    return word


def build_hidden_words(shape):
    """
    Gera palavras contendo até 2 larguras hidden por palavra.

    Novo formato:
    [31:16] -> hidden_1 (16b)
    [15:00] -> hidden_2 (16b)
    """

    hidden = list(shape[1:-1])

    words = []

    for i in range(0, len(hidden), 2):

        group = hidden[i:i+2]

        while len(group) < 2:
            group.append(0)

        h1, h2 = group

        for h in group:
            if h > 0xFFFF:
                raise ValueError(
                    f"Valor {h} excede 16 bits"
                )

        word = (
            ((h1 & 0xFFFF) << 16)
            | (h2 & 0xFFFF)
        )

        words.append(word)

    return words


def to_bin32(value):
    return format(value, "032b")


def to_hex8(value):
    return format(value, "08X")


#=========================================================
# Geracao da memoria
#=========================================================

memory = []
memory.append(1)                         # Start
memory.append(build_header_word(shape))  # Palavra de header
memory.extend(build_hidden_words(shape)) # Palavras hidden

#=========================================================
# Exibicao em tabela
#=========================================================

table = []

for addr, word in enumerate(memory):

    table.append([
        f"0x{addr:04X}",
        f"0x{to_hex8(word)}",
        to_bin32(word)
    ])

print("\n")
print("=" * 60)
print(" MAPA DE MEMORIA GERADO ")
print("=" * 60)
print("\n")

print(tabulate(
    table,
    headers=["ADDR", "HEX", "BIN"],
    tablefmt="grid"
))

print("\n")

#=========================================================
# Geracao do arquivo .mem
#=========================================================

with open("network.mem", "w") as f:
    for word in memory:
        f.write(to_bin32(word) + "\n")

#=========================================================
# Geracao do arquivo .hex
#=========================================================

with open("network.hex", "w") as f:
    for word in memory:
        f.write(to_hex8(word) + "\n")

#=========================================================
# Resumo
#=========================================================

print("Arquivos gerados com sucesso:")
print(" - network.mem")
print(" - network.hex")
print("\n")