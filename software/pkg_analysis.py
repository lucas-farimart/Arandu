# #==========================================================================
# Descricao: Comparacao de armazenamento de matrizes NxM (8 bits)
# usando palavras de 32 e 64 bits.
#
# O script:
#   - Mostra exemplos detalhados (5x5 e 10x10)
#   - Como as palavras ficam na memoria
#   - Gera tabela comparativa usando tabulate
# 
# Considera-se DOIS casos:
# 
#    1) Cada linha inicia em uma nova palavra.
#       Caso a linha nao complete multiplos de 4 bytes,
#       o restante da palavra eh preenchido com zeros.
#
#    2) Os bytes das linhas sao empacotados continuamente,
#       sem padding entre linhas.
#       Apenas a ultima palavra pode conter padding.
#-------------------------------------------------------------------------
# Autor: Lucas Farias Martis
# Email: lucas.martins@ee.ufcg.edu.br
# Data: 2026-05-18
# Uso de LLMs: sim
#==========================================================================

import math
import numpy as np

from tabulate import tabulate


# ============================================================
# Funcoes auxiliares
# ============================================================

def print_matrix(title, mat):

    print("=" * 70)
    print(title)
    print("=" * 70)

    for row in mat:
        print(" ".join(f"{v:3d}" for v in row))

    print()


def chunk_list(lst, chunk_size):

    return [
        lst[i:i + chunk_size]
        for i in range(0, len(lst), chunk_size)
    ]


def format_word(word_bytes):

    return " | ".join(f"{b:02X}" for b in word_bytes)


# ============================================================
# Empacotamento - CASO 1
# ============================================================

def pack_case1(matrix, word_bytes):

    memory = []

    for row in matrix:

        row_bytes = list(row)

        while len(row_bytes) % word_bytes != 0:
            row_bytes.append(0)

        words = chunk_list(row_bytes, word_bytes)

        memory.extend(words)

    return memory


# ============================================================
# Empacotamento - CASO 2
# ============================================================

def pack_case2(matrix, word_bytes):

    flat = matrix.flatten().tolist()

    while len(flat) % word_bytes != 0:
        flat.append(0)

    memory = chunk_list(flat, word_bytes)

    return memory


# ============================================================
# Impressao da memoria
# ============================================================

def print_memory(title, memory):

    print("-" * 70)
    print(title)
    print("-" * 70)

    for idx, word in enumerate(memory):

        print(
            f"Word[{idx:03d}] : "
            f"{format_word(word)}"
        )

    print()
    print(f"Total de palavras: {len(memory)}")
    print()


# ============================================================
# Exemplos detalhados
# ============================================================

def detailed_example(N, M, start_value=0):

    print("\n")
    print("#" * 80)
    print(f"EXEMPLO DETALHADO - MATRIZ {N}x{M}")
    print("#" * 80)
    print()

    matrix = np.arange(
        start_value,
        start_value + (N * M),
        dtype=np.uint8
    ).reshape(N, M)

    print_matrix("MATRIZ ORIGINAL", matrix)

    # ========================================================
    # 32 BITS
    # ========================================================

    print("=" * 70)
    print("PALAVRAS DE 32 BITS")
    print("=" * 70)
    print()

    mem_case1_32 = pack_case1(matrix, 4)
    mem_case2_32 = pack_case2(matrix, 4)

    print_memory(
        "CASO 1 - LINHAS ALINHADAS",
        mem_case1_32
    )

    print_memory(
        "CASO 2 - EMPACOTAMENTO CONTINUO",
        mem_case2_32
    )

    # ========================================================
    # 64 BITS
    # ========================================================

    print("=" * 70)
    print("PALAVRAS DE 64 BITS")
    print("=" * 70)
    print()

    mem_case1_64 = pack_case1(matrix, 8)
    mem_case2_64 = pack_case2(matrix, 8)

    print_memory(
        "CASO 1 - LINHAS ALINHADAS",
        mem_case1_64
    )

    print_memory(
        "CASO 2 - EMPACOTAMENTO CONTINUO",
        mem_case2_64
    )


# ============================================================
# Calculos quantitativos
# ============================================================

def calc_case1_words(N, M, word_bytes):
    words_per_row = math.ceil(M / word_bytes)
    return N * words_per_row


def calc_case2_words(N, M, word_bytes):
    total_bytes = N * M
    return math.ceil(total_bytes / word_bytes)


# ============================================================
# Exemplos detalhados
# ============================================================

detailed_example(5, 5)
detailed_example(10, 10, start_value=100)

# ============================================================
# Tabela comparativa expandida
# ============================================================

large_cases = [ 
    (3, 3),
    (3, 5),
    (5, 5),
    (10, 4),
    (11, 8),
    (12, 13),
    (32, 33),
    (32, 47),
    (32, 65),
    (64, 64),
    (64, 65),
    (64, 96),
    (128, 255),
    (256, 10),
    (256, 256),
    (256, 257),
    (256, 511),
    (512, 10),
    (512, 512),
    (512, 513),
    (1024, 1024),
    (1024, 1025),
    (1280, 720),
    (1920, 1080),
    (3840, 2160),
    (4096, 2160),
    (7680, 4320),
    (65392, 54021),
]

table = []

for N, M in large_cases:

    # ========================================================
    # 32 bits
    # ========================================================

    case1_32 = calc_case1_words(N, M, 4)
    case2_32 = calc_case2_words(N, M, 4)

    reduction32 = (
        (case1_32 - case2_32)
        / case1_32
    ) * 100

    # ========================================================
    # 64 bits
    # ========================================================

    case1_64 = calc_case1_words(N, M, 8)
    case2_64 = calc_case2_words(N, M, 8)

    reduction64 = (
        (case1_64 - case2_64)
        / case1_64
    ) * 100

    # ========================================================
    # Tabela
    # ========================================================

    table.append([
        N,
        M,

        case1_32,
        case2_32,
        f"{reduction32:.2f}%",

        case1_64,
        case2_64,
        f"{reduction64:.2f}%"
    ])


# ============================================================
# Exibe tabela
# ============================================================

headers = [
    "N","M",
    "32b C1","32b C2","% Red. 32b",
    "64b C1","64b C2","% Red. 64b",
]

print("\n")
print("  __  __                          __  __                _           ")
print(" |  \/  |___ _ __  ___ _ _ _  _  |  \/  |__ _ _ __ _ __(_)_ _  __ _ ")
print(" | |\/| / -_) '  \/ _ \ '_| || | | |\/| / _` | '_ \ '_ \ | ' \/ _` |")
print(" |_|  |_\___|_|_|_\___/_|  \_, | |_|  |_\__,_| .__/ .__/_|_||_\__, |")
print("                           |__/              |_|  |_|         |___/ ")
print("\n")

print("=" * 90)
print("\t\tTABELA COMPARATIVA")
print("=" * 90)

print(tabulate(
    table,
    headers=headers,
    tablefmt="fancy_grid"
))